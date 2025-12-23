plugins {
    kotlin("jvm") version "2.3.0-RC3"
    id("com.gradleup.shadow") version "8.3.5"
    application
    idea
}

idea {
    module {
        // Exclude these directories from IntelliJ's project view and indexing
        excludeDirs = excludeDirs + setOf(file(".direnv"), file(".jdk"), file("build"), file(".gradle"))
    }
}

group = "com.nannuo"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven("https://maven.pkg.jetbrains.space/kotlin/p/kotlin/bootstrap")
}

dependencies {
    implementation("dev.kord:kord-core:0.13.1")
    implementation("org.slf4j:slf4j-simple:2.0.9")
}

kotlin {
    jvmToolchain(25)
    
    compilerOptions {
        // Enable the new experimental checker mentioned in release notes
        freeCompilerArgs.add("-Xreturn-value-checker=check")
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