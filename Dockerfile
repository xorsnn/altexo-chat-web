FROM nginx:1.15.3
RUN mkdir /app
WORKDIR /app
COPY ./build /app
COPY ./scripts/conf/nginx-locations-prod.conf /etc/nginx/conf.d/nginx-locations-altexo-chat.conf
RUN rm /etc/nginx/conf.d/default.conf

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
