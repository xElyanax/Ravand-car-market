pluginManagement {
    includeBuild("/Users/elyananasiri/Development/flutter/packages/flutter_tools/gradle")

    repositories {
        maven {
            url = uri("https://mirror-maven.runflare.com/android/maven2/")
        }
        maven {
            url = uri("https://mirror-maven.runflare.com/maven2/")
        }
        maven {
            url = uri("https://mirror-maven.runflare.com/gradle-plugins/")
        }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = "ravand-gradle-probe"
