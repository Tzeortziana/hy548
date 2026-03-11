FROM nginx:1.25

RUN apt-get update && apt-get install -y bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]