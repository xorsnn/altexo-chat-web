FROM node:7.7.1
RUN mkdir /code
WORKDIR /code
ADD . /code/
# RUN npm install
# RUN npm install -g bower
