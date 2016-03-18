FROM python:3.4


EXPOSE 8000
WORKDIR "/src"
ENTRYPOINT ["./manage.py"]

ARG REQUIREMENTS=Django==1.9
RUN pip install $REQUIREMENTS
