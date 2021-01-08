#!/bin/bash
zip -d out/artifacts/Rover_jar/Rover.jar META-INF/ECLIPSE_.RSA
zip -d out/artifacts/Rover_jar/Rover.jar META-INF/ECLIPSE_.SF
scp out/artifacts/Rover_jar/Rover.jar pi@exomax:
