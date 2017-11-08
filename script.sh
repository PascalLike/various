#!/bin/bash

GN_SOURCES=core-geonetwork
GN_PROFILES=env-prod
DEPLOY_NAME=geonetwork
GN_DATA_DIR=/var/local/geonetwork/${DEPLOY_NAME}

RED='\e[31m'
EC='\e[0m'


cd ${GN_SOURCES}
branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
echo -e "Updating branch ${RED}${branch}${EC}..."

# Save local changes.
git stash save

# Pull branch from remote
git pull origin
git submodule update --init --recursive

# Apply the local changes
git stash pop


echo -e "${RED}Compiling ${GN_SOURCES}${EC}"

# Compile GN
mvn clean install -DskipTests -P${GN_PROFILES}
if [ $? -ne 0 ]; then
    echo -e "${RED}mvn clean install FAILED${EC}"
    exit -2
fi

echo  -e "${RED}Deleting old version and uncompressing WAR...${EC}"
cd ..
rm -rf ${DEPLOY_NAME}
unzip ${GN_SOURCES}/web/target/geonetwork.war -d ${DEPLOY_NAME}

echo -e "${RED}Customizing files to deploy${EC}"

echo -e "${RED}Stopping Tomcat, removing old deployed verion and cleaning wro4j cache...${EC}"
# Stop Tomcat, remove old deployed GN
service tomcat7 stop
rm -rf /var/lib/tomcat7/webapps/${DEPLOY_NAME}

# Delete wro4j cache
rm ${GN_DATA_DIR}/wro4j*

# Delete config folder to be repopulated on GN start
rm -rf ${GN_DATA_DIR}/config

echo -e "${RED}Deploying new version and starting Tomcat...${EC}"
# Deploy the new GN version and start Tomcat
mv ${DEPLOY_NAME} /var/lib/tomcat7/webapps/
service tomcat7 start
