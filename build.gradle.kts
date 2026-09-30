plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.shadow)
    application
    idea
}

idea {
    module {
        // Exclude these directories from IntelliJ's project view and indexing
        excludeDirs = excludeDirs + setOf(file(".direnv"), file(".jdk"), file("build"), file(".gradle"))
    }
}

val projectVersion: String by project
val javaVersion: String by project
val projectGroup: String by project

group = projectGroup
version = if (project.version != "unspecified") project.version else projectVersion

repositories {
    mavenCentral()
    // necessary for snapshot that fixes Cannot parse ULong from null #1075 https://github.com/kordlib/kord/issues/1075#issuecomment-5729187971
    maven("https://snapshots.kord.dev")
}

dependencies {
    implementation(libs.kord.core)
    implementation(libs.slf4j.simple)
}

kotlin {
    jvmToolchain(javaVersion.toInt())

    compilerOptions {
        // Enable the new experimental checker mentioned in release notes
        freeCompilerArgs.add("-Xreturn-value-checker=check")
        optIn.add("kotlin.time.ExperimentalTime") // Required: https://github.com/kordlib/kord/releases/tag/0.17.0
    }
}

application {
    mainClass.set("com.nannuo.MainKt")
}

tasks.withType<Jar> {
    manifest {
        attributes["Main-Class"] = "com.nannuo.MainKt"
    }
}
