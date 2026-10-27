allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val extension = project.extensions.findByName("android")
            if (extension != null) {
                try {
                    val getNamespace = extension.javaClass.getMethod("getNamespace")
                    val setNamespace = extension.javaClass.getMethod("setNamespace", String::class.java)
                    val currentNamespace = getNamespace.invoke(extension)
                    if (currentNamespace == null) {
                        val fallback = if (project.name == "on_audio_query_android") {
                            "com.lucasjosino.on_audio_query"
                        } else {
                            "com.tugtog.plugins.${project.name.replace('-', '_')}"
                        }
                        setNamespace.invoke(extension, fallback)
                    }
                } catch (e: Exception) {
                    // Ignore if namespace method is unavailable
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
