#!/bin/bash
#Este es un script que permite hacer cálculos moleculares usando ORCA para obtener los parametros Mossbauer de compuestos que contengan hierro. Una vez hechos los calculos puede extraer, del output de ORCA, los valores necesarios para calcular los parametros Mossbauer del compuesto y así obtener su respectivo espectro.

#El flujo de trabajo es el siguiente:

#En nuestra maquina local creamos el input de ORCA. Cada archivo de entrada debe estar en una carpeta diferente pero todas las carpetas estaran dentro de una, es decir, una carpeta contendra tantas carpetas como compuestos tengamos, cada compuesto en su respectiva carpeta.

#Una vez que se tienen los archivos de entrada queremos enviar la carpeta principal a la maquina remota. Para hacerlo la sintaxis es la siguiente:
#scp -r -P 223 /directorio_local/carpeta orca@132.248.7.196:/home/orca/.../carpeta
#Donde -r indica que queremos enviar un directorio o carpeta, en /directorio_local/carpeta corresponde a la ruta dentro de nuestra maquina local en donde se encuentra la carpeta principal que queremos enviar y finalmente /home/orca/.../carpeta corresponde a la ruta dentro de la maquina remota a donde queremos enviar nuesta carpeta con los compuestos.

#Una vez que tenemos la carpeta principal en la maquina remota ya podemos hacer los calculos moleculares con ORCA. Esto ya lo hace el scritp.

#Inicio del script:

#Definimos la variable 'ruta' como la ruta donde se encuentra la carpeta principal que contiene todas las carpetas con los compuestos. 

ruta=/home/orca/Mossbauer/compuestos                                    #Definimos la ruta principal en donde estan las carpetas
cd $ruta                                                                #Nos movemos a la carpeta principal

#Una vez que estamos en la carpeta principal recorreremos todas las carpetas haciendo los calculos correspondientes con ORCA.

for directorio in $(ls)                                                 #Creamos un for que corra ORCA para todos los compuestos
do 
	cd $ruta/$directorio                                            #Entramos a cada carpeta para leer el archivo de entrada de cada compuesto
	/home/orca/orca_421_314/orca input.inp > output.out &           #Corremos ORCA sobre cada archivo de entrada
	sleep 10m                                                       #Definimos un tiempo de espera para que se realice el calculo.
done

#Una vez hechos todos los calculos regresamos a la carpeta principal.

cd $ruta                                                 
mkdir Datos                                                             #Creamos un directorio donde almacenaremos los archivos de datos que generemos
touch datos.txt                                                         #Creamos un archivo .txt donde almacenaremos los valores que vamos a extraer

#El archivo creado pasara por todas las carpetas y almacenara dos lineas de texto que contienen los parametros que necesitamos, estas seran extraidas del archivo de salida de ORCA.

for directorio in $(ls)                                                 #Creamos un for que recorra las carpetas y extraiga los valores
do
	mv datos.txt $ruta/$directorio                                  #El archivo datos.txt lo movemos a traves de las carpetas
	cd $ruta/$directorio	                                        #Recorremos las carpetas
	grep -w "RHO(0)" output.out >> datos.txt                        #En cada carpeta entramos al archivo output.out, extraemos las lineas que nos interesan y las almacenamos en el archivo datos.txt
	grep -w "Delta-EQ" output.out >> datos.txt
done
  
#Hasta aqui tenemos un archivo con ambos valores para cada compuesto, ahora vamos a dividirlos es dos archivos uno para cada parametro.

cd $ruta                                                                #Regresamos a la carpeta principal
grep -w "RHO(0)" datos.txt > densidad.txt                               #Los valores de la densidad electronica los almacenamos en un archivo
grep -w "Delta-EQ" datos.txt > desdoblamiento.txt                       #Los valores del desdoblamiento cuadrupolar los almacenamos en otro archivo

#Ahora tenemos dos archivos cada uno con los parametros correspondientes sin embargo contiene toda la información de la linea de texto y lo que queremos son solo los valores numericos. Vamos a crear otros dos archivos en los que almacenemos estos valores:

cut -c 11-25 densidad.txt > datos01.txt                                 #Tomamos los valores numericos de la densidad electronica
cut -c 62-68 desdoblamiento.txt > datos02.txt                           #Tomamos los valores numericos del desdoblamiento cuadrupolar

#Al final tenemos 5 archivos de datos, todos los vamos a almacenar en la carpeta Datos.

mv datos.txt $ruta/Datos
mv densidad.txt $ruta/Datos
mv desdoblamiento.txt $ruta/Datos
mv datos01.txt $ruta/Datos
mv datos02.txt $ruta/Datos

#Con el fin de no tener muchos archivos de salida que no son utiles y que solo ocupan espacio los vamos a eliminar 

cd $ruta                                                                #Volvemos a la carpeta principal

for directorio in $(ls)                                                 #Hacemos un for que recorra todas las carpetas y elimine los archivos que no son utilies 
do
	cd $ruta/$directorio
        rm input.gbw
      	rm input.prop
	rm input_property.txt
	rm output.out
done

#Ahora podemos enviar la carpeta Datos a nuestra maquina local y levantar los archivos datos01.txt y datos02.txt con el notebook de espectros Mossbauer. 
#La manera de hacerlo es escribiendo en la terminal de nuestra maquina local lo siguiente:
#scp -r -P 223 orca@132.248.7.196:/home/orca/Mossbauer/compuestos/Datos /directorio_local
#Donde /directorio_local es el directorio de nuestra maquina local en donde queremos recibir la carpeta Datos. 
