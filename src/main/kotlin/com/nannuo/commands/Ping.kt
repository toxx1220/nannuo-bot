package com.nannuo.commands

import dev.kord.core.entity.Message

class Ping: Command {
    override val name: String = "ping"
    override val description: String = "Responds with Pong!"

    override suspend fun execute(
        message: Message,
        args: List<String>,
    ) {
        message.channel.createMessage("Pong!")
    }
}
