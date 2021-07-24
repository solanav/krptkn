let Updates = {
    init(socket) {
        console.log("Init Updates")
        let channel = socket.channel('live_updates:lobby', {})
        channel.join()
        this.listenForUpdates(channel)
    },

    listenForUpdates(channel) {
        // Update counts on top
        channel.on('count', payload => {
            let urlBox = document.querySelector(`#${payload.name}`)
            urlBox.innerHTML = payload.value
        })

        // Update the state LED
        channel.on('state', payload => {
            let color_html = ""

            if (payload.state == "running") {
                color_html = "<div class=\"led led-green\"></div>"
            } else if (payload.state == "stopped") {
                color_html = "<div class=\"led led-red\"></div>"
            } else if (payload.state == "paused") {
                color_html = "<div class=\"led led-yellow\"></div>"
            } else {
                color_html = "<div class=\"led led-blue\"></div>"
            }

            document.getElementById("queue_state").innerHTML = color_html
        })

        // Update the last urls visited
        channel.on('url', payload => {
            let nuHTML = ""

            for (var p of payload.urls) {
                nuHTML += `<tr><td>${p.index}</td><td>${p.url}</td></tr>`
            }

            document.getElementById("url_table").innerHTML = nuHTML
        })

        // Update the last metadata found
        channel.on('metadata', payload => {
            let nuHTML = ""

            for (var p of metadata) {
                nuHTML += "<tr><td><ul>";
                for (var key of Object.keys(p)) {
                    nuHTML += `<li>${key} -> ${p[key]}</li>`
                    console.log(`${key} -> ${p[key]}`)
                }
                nuHTML += "</ul></td></tr>";
            }

            document.getElementById("metadata_table").innerHTML = nuHTML
        })
    }
}

export default Updates