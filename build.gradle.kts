plugins {
    kotlin("jvm") version "2.3.10"
    id("com.gradleup.shadow") version "9.3.1"
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
version = projectVersion

repositories {
    mavenCentral()
}

dependencies {
    implementation("dev.kord:kord-core:0.17.0")
    implementation("org.slf4j:slf4j-simple:2.0.17")
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
