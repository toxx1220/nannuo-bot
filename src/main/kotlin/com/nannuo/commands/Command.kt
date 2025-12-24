package com.nannuo.commands

import dev.kord.core.entity.Message

interface Command {
    val name: String
    val description: String

    suspend fun execute(message: Message, args: List<String>)
}
