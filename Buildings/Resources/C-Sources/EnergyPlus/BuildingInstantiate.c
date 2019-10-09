/*
 * Modelica external function to intialize EnergyPlus.
 *
 * Michael Wetter, LBNL                  3/1/2018
 * Thierry S. Nouidui, LBNL              3/23/2018
 */

#include "BuildingInstantiate.h"
#include "EnergyPlusFMU.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "../cryptographicsHash.c"

void buildJSONModelStructureForEnergyPlus(
  const FMUBuilding* bui, char* *buffer, size_t* size, char** modelHash){
  int iZon;
  FMUZone** zones = (FMUZone**)bui->zones;

  saveAppend(buffer, "{\n", size);
  saveAppend(buffer, "  \"version\": \"0.1\",\n", size);
  saveAppend(buffer, "  \"EnergyPlus\": {\n", size);
  /* idf name */
  saveAppend(buffer, "    \"idf\": \"", size);
  saveAppend(buffer, bui->idfName, size);
  saveAppend(buffer, "\",\n", size);

  /* idd file */
  saveAppend(buffer, "    \"idd\": \"", size);
  saveAppend(buffer, bui->idd, size);
  saveAppend(buffer, "\",\n", size);

  /* weather file */
  saveAppend(buffer, "    \"weather\": \"", size);
  saveAppend(buffer, bui->weather, size);
  saveAppend(buffer, "\"\n", size);
  saveAppend(buffer, "  },\n", size);

  /* model information */
  saveAppend(buffer, "  \"model\": {\n", size);
  saveAppend(buffer, "    \"zones\": [\n", size);
  for(iZon = 0; iZon < bui->nZon; iZon++){
    /* Write zone name */
    if (FMU_EP_VERBOSITY >= MEDIUM)
      ModelicaFormatMessage("Writing zone data %s.\n", zones[iZon]->name);
    saveAppend(buffer, "        { \"name\": \"", size);
    saveAppend(buffer, zones[iZon]->name, size);
    if (iZon < (bui->nZon) - 1)
      saveAppend(buffer, "\" },\n", size);
    else
      saveAppend(buffer, "\" }\n", size);
  }
  /* Close json array for zones */
  saveAppend(buffer, "    ]\n  },\n", size);

  *modelHash = (char*)(cryptographicsHash(*buffer));

    /* fmu */
  saveAppend(buffer, "  \"fmu\": {\n", size);
  saveAppend(buffer, "      \"name\": \"", size);
  saveAppend(buffer, bui->fmuAbsPat, size);
  saveAppend(buffer, "\",\n", size);
  saveAppend(buffer, "      \"version\": \"2.0\",\n", size);
  saveAppend(buffer, "      \"kind\"   : \"ME\"\n", size);
  saveAppend(buffer, "  }\n", size);

  /* Close json structure */
  saveAppend(buffer, "}\n", size);

  return;
}


void writeModelStructureForEnergyPlus(const FMUBuilding* bui, char** modelicaBuildingsJsonFile, char** modelHash){
  char * buffer;
  size_t size;
  size_t lenNam;
  char * filNam;
  FILE* fp;

  /* Initial size which will grow as needed */
  size = 1024;

  mallocString(size+1, "Failed to allocate memory for json buffer.", &buffer);
  memset(buffer, '\0', size + 1);

  /* Build the json structure */
  buildJSONModelStructureForEnergyPlus(bui, &buffer, &size, modelHash);

  /* Write to file */
  /* Build the file name */
  lenNam = strlen(bui->tmpDir) + strlen(SEPARATOR) + strlen(MOD_BUI_JSON);

  mallocString(lenNam+1, "Failed to allocate memory for json file name.", modelicaBuildingsJsonFile);
  memset(*modelicaBuildingsJsonFile, '\0', lenNam+1);
  strcpy(*modelicaBuildingsJsonFile, bui->tmpDir);
  strcat(*modelicaBuildingsJsonFile, SEPARATOR);
  strcat(*modelicaBuildingsJsonFile, MOD_BUI_JSON);

  /* Open and write file */
  fp = fopen(*modelicaBuildingsJsonFile, "w");
  if (fp == NULL)
    ModelicaFormatError("Failed to open '%s' with write mode.", *modelicaBuildingsJsonFile);
  fprintf(fp, "%s", buffer);
  fclose(fp);
}

void setValueReference(
  const char* fmuNam,
  const char* inpSrcNam,
  fmi2_import_variable_list_t* varLis,
  const fmi2_value_reference_t varValRef[],
  size_t nVar,
  fmi2Byte** modNames,
  const size_t nNam,
  fmi2ValueReference** modValRef){

  size_t iMod;
  size_t iFMI;
  fmi2_import_variable_t* fmiVar;
  fmi2_value_reference_t vr;
  fmi2_import_variable_t* var;

  for (iMod = 0; iMod < nNam; iMod++){
    for (iFMI = 0; iFMI < nVar; iFMI++){
      var = fmi2_import_get_variable(varLis, iFMI);
      if (strcmp(modNames[iMod], fmi2_import_get_variable_name(var)) == 0){
        /* Found the variable */
        (*modValRef)[iMod] = varValRef[iFMI];
        break;
      }
    }
    if (iFMI == nVar){
      ModelicaFormatError("Failed to find variable %s in %s. Make sure it exists in %s.", modNames[iMod], fmuNam, inpSrcNam);
      }
    }
 }

void setValueReferences(FMUBuilding* fmuBui){
  size_t i;
  size_t iZon;
  size_t vr;
  FMUZone* zone;

  fmi2_import_variable_list_t* vl = fmi2_import_get_variable_list(fmuBui->fmu, 0);
  const fmi2_value_reference_t* vrl = fmi2_import_get_value_referece_list(vl);
  size_t nv = fmi2_import_get_variable_list_size(vl);

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Searching for variable reference.");
  /* Set value references for the parameters by assigning the values obtained from the FMU */
  for(iZon = 0; iZon < fmuBui->nZon; iZon++){
    zone = (FMUZone*) fmuBui->zones[iZon];
    setValueReference(
      fmuBui->fmuAbsPat,
      fmuBui->idfName,
      vl, vrl, nv,
      zone->parOutVarNames,
      ZONE_N_PAR_OUT,
      &(zone->parOutValReferences));
   setValueReference(
      fmuBui->fmuAbsPat,
      fmuBui->idfName,
      vl, vrl, nv,
      zone->inpVarNames,
      ZONE_N_INP,
      &(zone->inpValReferences));
   setValueReference(
     fmuBui->fmuAbsPat,
     fmuBui->idfName,
     vl, vrl, nv,
     zone->outVarNames,
     ZONE_N_OUT,
     &(zone->outValReferences));
  }
  fmi2_import_free_variable_list(vl);
  return;
}

void generateFMU(
  bool usePrecompiledFMU,
  const char* precompiledFMUPath,
  const char* FMUPath,
  const char* modelicaBuildingsJsonFile,
  const char* buildingsLibraryRoot){
  /* Generate the FMU */
  char* cmd;
  char* cmdFla;
  char* testFMU;
  char* fulCmd;
  size_t len;
  int retVal;
  struct stat st = {0};

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Entered generateFMU with FMUPath = %s.\n", FMUPath);

  if (usePrecompiledFMU){
    if( access( precompiledFMUPath, F_OK ) == -1 ) {
      ModelicaFormatError("Requested to use fmu '%s' which does not exist.", precompiledFMUPath);
    }
    cmd = "cp -p ";
    len = strlen(cmd) + strlen(FMUPath) + 1 + strlen(precompiledFMUPath) + 1;
    mallocString(len, "Failed to allocate memory in generateFMU().", &fulCmd);

    memset(fulCmd, '\0', len);
    strcpy(fulCmd, cmd);
    strcat(fulCmd, precompiledFMUPath);
    strcat(fulCmd, " ");
    strcat(fulCmd, FMUPath);
  }
  else{
    if( access(modelicaBuildingsJsonFile, F_OK ) == -1 ) {
      ModelicaFormatError("Requested to use json file '%s' which does not exist.", modelicaBuildingsJsonFile);
    }
    cmd = "/Resources/bin/spawn-linux64/bin/spawn";
    cmdFla = "-c"; /* Flag for command */
    /* The + 1 are for spaces, the quotes around the file name (needed if the Modelica name has array brackets) and
       the end of line character */
    len = strlen(buildingsLibraryRoot) + strlen(cmd) + 1 + strlen(cmdFla) + 1 + 1 + strlen(modelicaBuildingsJsonFile) + 1 + 1;

    mallocString(len, "Failed to allocate memory in generateFMU().", &fulCmd);
    memset(fulCmd, '\0', len);
    strcpy(fulCmd, buildingsLibraryRoot); /* This is for example /mtn/shared/Buildings */
    strcat(fulCmd, cmd);
    /* Check if the executable exists */
    if( access(fulCmd, F_OK ) == -1 ) {
      ModelicaFormatError("Executable '%s' does not exist.", fulCmd);
    }
    /* Make sure the file is executable */
    if( access(fulCmd, X_OK ) == -1 ) {
      ModelicaFormatError("File '%s' exists, but fails to be executable.", fulCmd);
    }
    /* Continue building the command line */
    strcat(fulCmd, " ");
    strcat(fulCmd, cmdFla);
    strcat(fulCmd, " \"");
    strcat(fulCmd, modelicaBuildingsJsonFile);
    strcat(fulCmd, "\"");
  }


  /* Remove the old fmu if it already exists */
  if (stat(FMUPath, &st) != -1) {
    /* FMU exists. Delete it. */
    retVal = remove(FMUPath);
    if (retVal != 0){
      ModelicaFormatError("Failed to remove old FMU %s", FMUPath);
   }
  }

  /* Copy or generate the FMU */
  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Executing %s\n", fulCmd);

  retVal = system(fulCmd);
  /* Check if generated FMU indeed exists */
  if( access( FMUPath, F_OK ) == -1 ) {
    ModelicaFormatError("Executing '%s' failed to generate fmu '%s'.", fulCmd, FMUPath);
  }
  if (retVal != 0){
    fprintf(stdout, "*** Warning: Generating FMU returned value %d, but FMU exists.\n", retVal);
/*    ModelicaFormatError("Generating FMU failed using command '%s', return value %d.", fulCmd, retVal);*/
  }
  free(fulCmd);
}


/* Set the categories to be logged.
   Note that EnergyPlus has the following levels:
      <Category name="logLevel1" description="logLevel1 - fatal error" />
		  <Category name="logLevel2" description="logLevel2 - error" />
		  <Category name="logLevel3" description="logLevel3 - warning" />
		  <Category name="logLevel4" description="logLevel4 - info" />
		  <Category name="logLevel5" description="logLevel5 - verbose" />
		  <Category name="logLevel6" description="logLevel6 - debug" />
   FMU_EP_VERBOSITY is 1, 2, 3 up to and including 6
*/
void setFMUDebugLevel(FMUBuilding* bui){
  fmi2_string_t* categories;
  size_t i;
  fmi2Status status;

  /* Get the number of log categories defined in the XML */
  const size_t nCat = fmi2_import_get_log_categories_num(bui->fmu);
  if (nCat < FMU_EP_VERBOSITY){
    ModelicaFormatError("FMU %s specified %u categories, but require at least %u categories.",
      bui->fmuAbsPat, nCat, FMU_EP_VERBOSITY);
  }

  /* Get the log categories that we need */
  categories = NULL;
  categories = (fmi2_string_t*)malloc(FMU_EP_VERBOSITY * sizeof(fmi2_string_t));
  if (categories == NULL){
    ModelicaFormatError("Failed to allocate memory for error categories for FMU %s", bui->fmuAbsPat);
  }
  /* Assign the categories as specified in modelDescription.xml */
  for(i=0; i < FMU_EP_VERBOSITY; i++){
    categories[i] = fmi2_import_get_log_category(bui->fmu, i);
  }

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Setting debug logging.");
  status = fmi2_import_set_debug_logging(
    bui->fmu,
    fmi2_true,        /* Logging on */
    (size_t)FMU_EP_VERBOSITY, /* nCategories */
    categories);        /* Which categories to log */
  if( status != fmi2_status_ok ){
    ModelicaMessage("Log categories:");
    for(i = 0; i < FMU_EP_VERBOSITY; i++){
      ModelicaFormatMessage("  Category[%u] = '%s'", i, categories[i]);
    }
    ModelicaFormatError("fmi2SetDebugLogging returned '%s' for FMU with name %s. Verbosity = %u", fmi2_status_to_string(status), bui->fmuAbsPat, FMU_EP_VERBOSITY);
  }
  /* Free storage */
  free(categories);
}

/* Import the EnergyPlus FMU
*/
void importEnergyPlusFMU(FMUBuilding* bui){
  const fmi2Boolean visible = fmi2False;

  /* fmi2_import_model_counts_t  mc; */
  fmi2_callback_functions_t callBackFunctions;
  jm_callbacks* callbacks;
  fmi_version_enu_t version;
  fmi2_fmu_kind_enu_t fmukind;
  jm_status_enu_t jm_status;

  const char* tmpPath = bui->tmpDir;
  const char* FMUPath = bui->fmuAbsPat;

  /* Set callback functions */
  callbacks = jm_get_default_callbacks();

  bui->context = fmi_import_allocate_context(callbacks);

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Getting fmi version.");
  version = fmi_import_get_fmi_version(bui->context, FMUPath, tmpPath);

  if (version != fmi_version_2_0_enu){
    ModelicaFormatError("Wrong FMU version for %s, require FMI 2.0 for Model Exchange, received %s.",
    FMUPath, fmi_version_to_string(version));
  }

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Parsing xml file %s", tmpPath);
  bui->fmu = fmi2_import_parse_xml(bui->context, tmpPath, 0);
	if(!bui->fmu) {
		ModelicaFormatError("Error parsing XML for %s.", FMUPath);
	}

	/* modelName = fmi2_import_get_model_name(bui->fmu); */
	bui->GUID = fmi2_import_get_GUID(bui->fmu);

  fmukind = fmi2_import_get_fmu_kind(bui->fmu);
  if(fmukind != fmi2_fmu_kind_me){
    ModelicaFormatError("Unxepected FMU kind for %s, require ME.", FMUPath);
  }

  /* Get model statistics
  fmi2_import_collect_model_counts(bui->fmu, &mc);
  printf("*** Number of discrete variables %u.\n", mc.num_discrete);
 */
  callBackFunctions.logger = fmi2_log_forwarding; /* fmilogger; */
  callBackFunctions.allocateMemory = calloc;
  callBackFunctions.freeMemory = free;
  callBackFunctions.componentEnvironment = bui->fmu;

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Loading dllfmu.");

  jm_status = fmi2_import_create_dllfmu(bui->fmu, fmukind, &callBackFunctions);
  if (jm_status == jm_status_error) {
  	ModelicaFormatError("Could not create the DLL loading mechanism (C-API) for %s.", FMUPath);
  }
  else{
    bui->dllfmu_created = fmi2_true;
  }

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Instantiating fmu.");

  /* Instantiate EnergyPlus */
  jm_status = fmi2_import_instantiate(
    bui->fmu,
    bui->modelicaNameBuilding,
    fmi2_model_exchange,
    NULL,
    visible);

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Returned from instantiating fmu.");
  if(jm_status == jm_status_error){
    ModelicaFormatError("Failed to instantiate building FMU with name %s.",  bui->modelicaNameBuilding);
  }
  /* Set the debug level in the FMU */
  setFMUDebugLevel(bui);
}

void setReusableFMU(FMUBuilding* bui){
  int iBui;
  FMUBuilding* ptrBui;

  for(iBui = 0; iBui < getBuildings_nFMU(); iBui++){
    ptrBui = (FMUBuilding*)(getBuildingsFMU(iBui));
    if ((iBui != bui->iFMU) && (ptrBui->modelHash != NULL)){
      if (strcmp(bui->modelHash, ptrBui->modelHash) == 0 ){
        /* Check if the FMU indeed was generated */
        if( access( ptrBui->fmuAbsPat, F_OK ) != -1 ) {
          /* We can use the same FMU as will be used for building iBui */
          bui->usePrecompiledFMU = true;
          bui->precompiledFMUAbsPat = ptrBui->fmuAbsPat;
        }
      }
    }
  }
}

void generateAndInstantiateBuilding(FMUBuilding* bui){
  /* This is the first call for this idf file.
     Allocate memory and load the fmu.
  */
  char* modelicaBuildingsJsonFile;

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("Entered ZoneAllocateAndInstantiateBuilding.\n");

  if (bui->usePrecompiledFMU)
    ModelicaFormatMessage("Using pre-compiled FMU %s\n", bui->precompiledFMUAbsPat);

  /* Write the model structure to the FMU Resources folder so that EnergyPlus can
     read it and set up the data structure.
  */
  writeModelStructureForEnergyPlus(bui, &modelicaBuildingsJsonFile, &(bui->modelHash));

  setReusableFMU(bui);

  generateFMU(
      bui->usePrecompiledFMU,
      bui->precompiledFMUAbsPat,
      bui->fmuAbsPat,
      modelicaBuildingsJsonFile,
      bui->buildingsLibraryRoot);
  free(modelicaBuildingsJsonFile);

  if( access( bui->fmuAbsPat, F_OK ) == -1 ) {
    ModelicaFormatError("Requested to load fmu '%s' which does not exist.", bui->fmuAbsPat);
  }

  importEnergyPlusFMU(bui);

  if (FMU_EP_VERBOSITY >= MEDIUM)
    ModelicaFormatMessage("FMU for building %s is at %p.\n", bui->modelicaNameBuilding, bui->fmu);

  /* Set the value references for all parameters, inputs and outputs */
  setValueReferences(bui);

  return;
}