#!/bin/bash

#Script for packaging files into individual "volumes"

#Author: Cody Adkins
#10/10/2020


#DECLARE VARIABLES
_SOURCE_DIR=$1;
_TARGET_DIR=$2;
_CACHE_DIR="/CACHE";
_VOL_DIR="/Vols";
_NO_VOLS=0;

#Size in GB
_VOLUME_SIZE=$4*1000000;

#KB
_VOLUME_SIZE_COMPUTED=$((_VOLUME_SIZE*2));


_VOLUME_SIZE_USED=0;



#CHECK IF WE HAVE SUPPLIED ALL OF THE RELEVANT ARGUMENTS
if [[ -z "$_SOURCE_DIR" ]] || [[ -z "$_TARGET_DIR" ]] || [[ -z "$_CACHE_DIR" ]] || [[ -z "$_VOLUME_SIZE" ]];then

    echo "Can not proceed, improper arugments format...";
    echo "DIR DIR CACHE VOLUME"

else
    echo "Processing Arguments...."
    
    ##DO SOME THINGS
    if [ ! -d "$_SOURCE_DIR" ];then
      echo "The source Directory is Invalid..."
      exit 27;
    fi;
    
     if [ -d "$_TARGET_DIR" ];then
      echo "The Target Directory Exists, Please Specify a New Directory . Exiting..."
      exit 26;
    fi;
    
    
    
    
    _VOLZC=$(echo $_VOLUME_SIZE_COMPUTED | awk '{ byte = $1 /1024/2 ;print byte " M";}');
    
    echo "Building Volumes of Approximatley the Size Of: $_VOLZC"
    
    echo "Scanning File System, Please Wait...."
 
 
   if [ -d "$_CACHE_DIR" ];then
   
       rm -rf "$_CACHE_DIR";
      
     
   fi
   
   mkdir -p "$_CACHE_DIR"
   
 
    for _FILE in $(find $_SOURCE_DIR -type f );do
         
         
          #Get the Size in Bytes
          _SIZE=$(du "$_FILE"|awk -F' ' '{print $1}')
        
          
        
          _VOLUME_SIZE_USED=$((_VOLUME_SIZE_USED+_SIZE));
        
       
        
        if [ "$_VOLUME_SIZE_USED" -lt "$_VOLUME_SIZE_COMPUTED" ];then
        
            # echo "$_FILE,$_SIZE"
             
             _VOLUME_SIZE_USED=$((_VOLUME_SIZE_USED+_SIZE))
           
             
            cp -R "$_FILE" "$_CACHE_DIR/";
          
          #echo "$_VOLUME_SIZE_USED || $_VOLUME_SIZE_COMPUTED"
        
        else
          
          #echo "$_VOLUME_SIZE_USED || $_VOLUME_SIZE_COMPUTED"
          
         
          echo ""
          echo "Splitting Volume ....."
          
          _NO_VOLS=$((_NO_VOLS+1))
          
          echo "Volume ID: A000-$_NO_VOLS"
           _VOLUME_SIZE_USED_THEOR=$(echo "$_VOLUME_SIZE_USED" | awk '{ byte = $1 /1024/2 ;print byte " M";}')
           _VOLUME_SIZE_COMPUTED_THEOR=$(echo "$_VOLUME_SIZE_COMPUTED"|awk '{ byte = $1 /1024/2 ;print byte " M";}');
          echo "Expected Space: $_VOLUME_SIZE_COMPUTED_THEOR vs Actual Space: $_VOLUME_SIZE_USED_THEOR"
          _ONDISK=$(du -h $_CACHE_DIR);
         
          echo "Size on Disk: $_ONDISK"
          
          
          #Move the .cache to a new volume.
          
          if [ ! -d "$_VOL_DIR/$_NO_VOLS" ];then
            mkdir -p "$_VOL_DIR/$_NO_VOLS"
          
            mv "$_CACHE_DIR" "$_VOL_DIR/$_NO_VOLS/"
          
            _VOLUME_SIZE_USED=0;
            
            #BUILD THE NEW CACHE DIR
             mkdir -p "$_CACHE_DIR"
             
             #TRY FILE COPY AGAIN
             cp -R "$_FILE" "$_CACHE_DIR/";
             
          fi
         
        
          
        
        fi
        
        
       
    
    done

 
 
 
 
 
 
 


fi


