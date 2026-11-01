// Runs at Jenkins start-up: creates the Declarative Pipeline job and triggers build #1
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.get()
def script  = new File(jenkins.rootDir, 'Jenkinsfile.seed').text
def job     = jenkins.getItem('sentiment-pipeline') ?: jenkins.createProject(WorkflowJob, 'sentiment-pipeline')
job.setDefinition(new CpsFlowDefinition(script, true))
job.save()
if (job.getLastBuild() == null) {
    job.scheduleBuild2(0)
}
