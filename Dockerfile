# Hi.Events all-in-one (nginx, PHP-FPM, Node SSR frontend, queue worker, scheduler)
# Official image, pinned by version and digest. Bump both together.
FROM daveearley/hi.events-all-in-one:v2.2.0@sha256:cd22770bab1a705c869453ad66b8f82d1d7cfd1a59be951a3e655cb4ced4914b

COPY railway-start.sh /railway-start.sh
RUN chmod 755 /railway-start.sh

CMD ["/railway-start.sh"]
