# Local Jenkins with the Pipeline plugins preinstalled, setup wizard skipped,
# and the sentiment-pipeline job created + built automatically on start.
FROM jenkins/jenkins:lts-jdk17
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
RUN jenkins-plugin-cli --plugins workflow-aggregator pipeline-stage-view
COPY Jenkinsfile /usr/share/jenkins/ref/Jenkinsfile.seed
COPY create-job.groovy /usr/share/jenkins/ref/init.groovy.d/create-job.groovy
