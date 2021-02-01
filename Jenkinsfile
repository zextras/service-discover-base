pipeline {
    agent {
        node {
            label 'base-agent-v1'
        }
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Stash') {
            steps {
                stash includes: "*", name: 'project'
            }
        }
        stage('Ubuntu 16.04') {
            agent {
                node {
                    label 'pacur-agent-ubuntu-16.04-v1'
                }
            }
            steps {
                unstash 'project'
                sh 'pacur-build'
            }
            post {
                always {
                    archiveArtifacts artifacts: "artifacts/*.deb", fingerprint: true
                }
            }
        }
        stage('Centos 7') {
            agent {
                node {
                    label 'pacur-agent-centos-7-v1'
                }
            }
            steps {
                unstash 'project'
                sh 'pacur-build'
            }
            post {
                always {
                    archiveArtifacts artifacts: "artifacts/*.rpm", fingerprint: true
                }
            }
        }

        stage('Upload') {
            when {
                buildingTag()
            }
            steps {
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo = Artifactory.newBuildInfo()

                    def uploadSpec = """{
								"files": [
								    {
										"pattern": "service-discover-base**/*.deb",
										"target": "debian-local/pool/",
										"props": "deb.distribution=xenial;deb.component=main;deb.architecture=amd64"
									},
									{
										"pattern": "service-discover-base**/*.deb",
										"target": "debian-local/pool/",
										"props": "deb.distribution=bionic;deb.component=main;deb.architecture=amd64"
									},
									{
										"pattern": "service-discover-base*/*.deb",
										"target": "debian-local/pool/",
										"props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
									},
									{
										"pattern": "service-discover-base*/(*)-(*)-(*).rpm",
										"target": "rpm-local/zextras/{1}/{1}-{2}-{3}.rpm",
										"props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=Zextras"
									}
								]
							}"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }
    post {
        always {
            script {
                GIT_COMMIT_EMAIL = sh(
                        script: 'git --no-pager show -s --format=\'%ae\'',
                        returnStdout: true
                ).trim()
            }
            emailext attachLog: true, body: '$DEFAULT_CONTENT', recipientProviders: [requestor()], subject: '$DEFAULT_SUBJECT', to: "${GIT_COMMIT_EMAIL}"
        }
    }
}