version: '3.7'

services:
  ${PROJECT_NAME}-php:
    container_name: ${PROJECT_NAME}-php
    restart: always
    image: gnualex/symfony-php-fpm:7.4
    volumes:
      - ./application:${PROJECT_DOCKER_DIR}
    networks:
      - ${PROJECT_NAME}

  ${PROJECT_NAME}-nginx:
    container_name: ${PROJECT_NAME}-nginx
    image: gnualex/symfony-nginx:1.18.0
    restart: always
    volumes:
      - ./application:${PROJECT_DOCKER_DIR}
    ports:
      - ${NGINX_PORT}:80
    environment:
      - PROJECT_NAME=${PROJECT_NAME}
      - PROJECT_DOCKER_DIR=${PROJECT_DOCKER_DIR}
      - PHP_SERVICE_NAME=${PROJECT_NAME}-php
    networks:
      - ${PROJECT_NAME}

networks:
  ${PROJECT_NAME}:
    name: ${PROJECT_NAME}
    driver: bridge