properties(
	[buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5')), pipelineTriggers([cron('H/15 * * * *')]),
    parameters(
		[choice(choices: 
			[
                'dev', 
                'qa', 
                'stage', 
                'prod'
            ], 
		description: 'Which Environment should we deploy?', 
		name: 'ENVIRONMENT')])]
)

node {
    stage("Pull"){
        checkout([$class: 'GitSCM', branches: [[name: 'october2021']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/roseyildiztas/infrastructure.git']]])
    }
    stage("Initialize"){
        ws("workspace/infrastructura/vpc"){
            sh "export ENVIRONMENT=${ENVIRONMENT}"
            sh "make i"
        }
    }
    stage("Format"){
        ws("workspace/infrastructura/vpc"){
            sh "export ENVIRONMENT=${ENVIRONMENT}"
            sh "make f"
        }
    }
    stage("Plan"){
        ws("workspace/infrastructura/vpc"){
            sh "export ENVIRONMENT=${ENVIRONMENT}"
            sh "make p"
        }
    }
    stage("Apply"){
         ws("workspace/infrastructura/vpc"){
            sh "export ENVIRONMENT=${ENVIRONMENT}"
            sh "make a"
        }
    }
    stage("Clean"){
        ws("workspace/infrastructura/vpc"){
            sh "export ENVIRONMENT=${ENVIRONMENT}"
            sh "make c"
        }
	}
}
