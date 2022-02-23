node {
    properties(
	[buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5')), 
    parameters(
		[string(defaultValue: 'apply', description: 'Should I build or destroy? ', name: 'TF_ACTION', trim: true),
        choice(choices: 
			[
                'dev', 
            ], 
		description: 'Which Environment should we deploy?', 
		name: 'ENVIR')])])
	stage("Clone a Repo"){
        checkout([$class: 'GitSCM', branches: [[name: 'october2021']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/farrukh90/jenkins-class.git']]])
    }
	stage("Build EC2"){
		ws("${workspace}/AWS/EC2"){
            sh "ENVIRONMENT=${ENVIR}   make tf-fmt  tf-init  tf-plan  tf-${TF_ACTION}"
        }
    }
	stage("Send Notification"){
		echo "hello"
    }
}
