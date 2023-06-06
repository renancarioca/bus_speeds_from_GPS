# Calculating bus speeds in specific segments from GPS data
Buses are the main form of public transportation in many cities, and usually the spinal cord of how people move, but the way streets are designed often penalizes people that use buses. Despite moving more people at once, buses are commonly stuck in traffic jams caused *by cars*.

<img width="950" alt="Screen Shot 2023-06-06 at 10 55 25" src="https://github.com/renancarioca/bus_speeds_from_GPS/assets/11481007/b7f9b8b9-c744-4b02-a43a-3a35e0860bd8">

**This set of codes aims to support the process of calculating and illustrating bus speeds in different streets. It only requires GPS data (periodically emitted by onboarded equipment in buses) and the monitoring network (designed by the user as a KML file, for instance in Google MyMaps).**

## Adapting the codes for the city you want to monitor
This repository uses data from Rio de Janeiro (available in data.rio) as a template. In order to apply it to the bus system(s) you want to monitor, you must clone the repository and adapt the codes.

This can be done by:
* Specifying the network of streets where you want to monitor bus speeds. To do this, use Google My Maps to design a KML layer where every line is a street or street segment where you want to calculate bus speeds.
* Uploading the GPS files of the buses in the transportation system you want to monitor. The file must be a .csv file separated by a semicolon (; or another separator, you can change that in the function), and each GPS record must contain at least an identifier for the bus (e.g. its plate), a timestamp, and the coordinates.

### Designing the monitoring network
Use [Google My Maps]([url](https://www.google.com/maps/about/mymaps/)) to design the network of streets where you want to monitor bus speeds. To do this, create a layer and create line segments to indicate where you want to calculate average bus speeds.

Here are some tips that will help you organize that process:
* Follow the street trajectory to the best extent you can. This will help you better illustrate it in the map.
* One street can be broken down in different segments, to better represent different contexts (e.g. some parts may be more congested due to traffic jams). Try to ensure segments are at least 500m.
* Name each line segment after the street (or segment) you are monitoring, add the direction in case of a two-way street to help you differentiante them (for instance, Street A - N/S and Street A - S/N).
* If the street is broken down in more than one segment, you can keep the same name and add identifiers as numbers, e.g. "Street A - N/S - 1" and "Street A - N/S - 2."

<img width="950" alt="Screen Shot 2023-06-06 at 10 49 21" src="https://github.com/renancarioca/bus_speeds_from_GPS/assets/11481007/81cf64d7-23ff-4fd9-a791-9f8389704c5b">

Export the layer as a KML, opting out to "keep the data up to date" and ensuring it is a KML and not a KMZ.

In the '0-code_setup.R' file, indicate your monitoring network by changing the location of the **monitoring_network_kml_file**.

<img width="950" alt="Screen Shot 2023-06-06 at 10 50 13" src="https://github.com/renancarioca/bus_speeds_from_GPS/assets/11481007/0993fa7e-16c2-408f-b3ff-56c0188bb11a">

### Using the GPS files for the bus system you are working with
Use the '0-code_setup.R' file to 

In the '0-code_setup.R' file, specify the folder where you are storing your GPS files by changing the _GPS_path_ variable.

The files must be a .csv, with a semicolon (;) as a separator. You can change the column separator and the decimal separator (defaulted as the dot '.') in the '0-code setup.R' file.

You can indicate which columns represent the key columns in the GPS files by changing the characters for the following variables:
* *bus_identifier* - representing a unique id for each bus, like a bus plate or device unique id.
* *timestamp* - it must be a character in a YYYY-MM-DD HH:MM:SS format, or else the code will not be able to translate it into a data format.
* *latitude_identifier* and *longitude_identifier* - identifiers for the coordinates. Ensure the decimal separator is adequate to the GPS file.

## Getting the results
The results are stored in the 2outputs folder and presented in two ways:
* A report in the form of a .csv file containing the calculated speed for each bus pass, and that can be later aggregated in whichever way is more convenient to your application.
* Maps illustrating the average bus speeds for each segment in the monitoring network, aggregated by:
  * Type of day (weekday, Saturdays, or Sundays - it does not account for holidays yet)
  * Month, identified as YYYY-MM
  * Period of the day:
    * 6AM - 9AM
    * 9AM - 4PM
    * 4PM - 7PM
    * 7PM - 6AM
