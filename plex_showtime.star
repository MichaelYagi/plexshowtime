"""
Applet: API text
Summary: API text display
Description: Display text from an API endpoint.
Author: Michael Yagi
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    random.seed(time.now().unix)

    plex_server_url = config.str("plex_server_url", "")
    plex_api_key = config.str("plex_api_key", "")
    font_color = config.str("font_color", "#FFFFFF")
    show_recent = config.bool("show_recent", True)
    show_added = config.bool("show_added", True)
    show_library = config.bool("show_library", True)
    filter_movie = config.bool("filter_movie", True)
    filter_tv = config.bool("filter_tv", True)
    filter_music = config.bool("filter_music", True)
    show_playing = config.bool("show_playing", True)
    fit_screen = config.bool("fit_screen", True)

    ttl_seconds = 5
    debug_output = True

    plex_endpoints = []

    if show_playing == True:
        plex_endpoints.append({"title": "Now Playing", "endpoint": "/status/sessions"})

    if show_added == True:
        plex_endpoints.append({"title": "Recently Added", "endpoint": "/library/recentlyAdded"})

    if show_recent == True:
        plex_endpoints.append({"title": "Recently Played", "endpoint": "/status/sessions/history/all?sort=viewedAt:desc"})

    if show_library == True:
        plex_endpoints.append({"title": "Plex Library", "endpoint": "/library/recentlyAdded"})

    endpoint_map = {"title": "Plex", "endpoint": ""}
    if len(plex_endpoints) > 0:
        endpoint_map = plex_endpoints[int(get_random_index("rand", plex_endpoints, debug_output))]

    if debug_output:
        print("------------------------------")
        print("CONFIG - plex_server_url: " + plex_server_url)
        print("CONFIG - plex_api_key: " + plex_api_key)
        print("CONFIG - ttl_seconds: " + str(ttl_seconds))
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - endpoint_map: " + str(endpoint_map))
        print("CONFIG - show_recent: " + str(show_recent))
        print("CONFIG - show_added: " + str(show_added))
        print("CONFIG - show_playing: " + str(show_playing))
        print("CONFIG - filter_movie: " + str(filter_movie))
        print("CONFIG - filter_tv: " + str(filter_tv))
        print("CONFIG - filter_music: " + str(filter_music))
        print("CONFIG - font_color: " + font_color)
        print("CONFIG - fit_screen: " + str(fit_screen))

    return get_text(plex_server_url, plex_api_key, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, font_color, ttl_seconds)

def get_text(plex_server_url, plex_api_key, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, font_color, ttl_seconds):
    if plex_server_url == "" or plex_api_key == "":
        if debug_output:
            print("Plex API URL and Plex API key must not be blank")
        return display_banner(debug_output)
    elif endpoint_map["title"] == "Plex":
        return display_banner(debug_output)
    else:
        headerMap = {
            "Accept": "application/json",
            "X-Plex-Token": plex_api_key,
        }

        api_endpoint = plex_server_url
        if plex_server_url.endswith("/"):
            api_endpoint = plex_server_url[0:len(plex_server_url) - 1] + endpoint_map["endpoint"]
        else:
            api_endpoint = plex_server_url + endpoint_map["endpoint"]

        # Get Plex API content
        content = get_data(api_endpoint, debug_output, headerMap, ttl_seconds)

        if content != None and len(content) > 0:
            output = json.decode(content, None)

            if output != None:
                output_keys = output.keys()
                valid_map = False
                for key in output_keys:
                    if debug_output:
                        print("key: " + str(key))
                    if key == "MediaContainer":
                        valid_map = True
                        break

                if valid_map == True:
                    icon_img = get_data("https://michaelyagi.github.io/images/plex_icon.png", debug_output, {}, 604800)
                    marquee_text = endpoint_map["title"]
                    img = get_data("https://michaelyagi.github.io/images/plex_banner.png", debug_output, headerMap, 604800)

                    if output["MediaContainer"]["size"] > 0:
                        if filter_movie and filter_music and filter_tv:
                            metadata_list = output["MediaContainer"]["Metadata"]
                            if endpoint_map["title"] != "Plex Library" and len(metadata_list) > 9:
                                metadata_list = metadata_list[0:9]
                        else:
                            m_list = output["MediaContainer"]["Metadata"]
                            metadata_list = []
                            for metadata in m_list:
                                keys = metadata.keys()
                                is_clip = False
                                for key in keys:
                                    if key == "subtype" and metadata["subtype"] == "clip":
                                        is_clip = True
                                        break

                                if filter_movie and metadata["type"] == "movie" and is_clip == False:
                                    metadata_list.append(metadata)
                                if filter_tv and is_clip:
                                    metadata_list.append(metadata)
                                if filter_music and metadata["type"] == "album":
                                    metadata_list.append(metadata)
                                if filter_tv and metadata["type"] == "season":
                                    metadata_list.append(metadata)
                                if endpoint_map["title"] != "Plex Library" and len(metadata_list) > 9:
                                    break

                        if len(metadata_list) > 0:
                            random_index = random.number(0, len(metadata_list) - 1)
                            metadata_keys = metadata_list[random_index].keys()

                            if debug_output:
                                print("List size: " + str(len(metadata_list)))
                                print("Random index: " + str(random_index))

                            base_url = plex_server_url
                            if base_url.endswith("/"):
                                base_url = base_url[0:len(base_url) - 1]

                            img = None
                            art_type = ""

                            is_clip = False
                            for key in metadata_keys:
                                if key == "subtype" and metadata_list[random_index]["subtype"] == "clip":
                                    is_clip = True
                                    break

                            # thumb if art not available
                            for key in metadata_keys:
                                if key == "art":
                                    art_type = key
                                    img = get_data(base_url + metadata_list[random_index][key], debug_output, headerMap, ttl_seconds)
                                    break
                                if key == "parentArt":
                                    art_type = key
                                    img = get_data(base_url + metadata_list[random_index][key], debug_output, headerMap, ttl_seconds)
                                    break
                                if key == "grandparentArt":
                                    art_type = key
                                    img = get_data(base_url + metadata_list[random_index][key], debug_output, headerMap, ttl_seconds)
                                    break
                                elif key == "thumb" and metadata_list[random_index]["thumb"].endswith("/-1") == False:
                                    art_type = key
                                    img = get_data(base_url + metadata_list[random_index][key], debug_output, headerMap, ttl_seconds)
                                elif key == "parentThumb":
                                    art_type = key
                                    img = get_data(base_url + metadata_list[random_index][key], debug_output, headerMap, ttl_seconds)
                                elif key == "grandparentThumb":
                                    art_type = key
                                    img = get_data(base_url + metadata_list[random_index][key], debug_output, headerMap, ttl_seconds)

                            if img == None:
                                if debug_output:
                                    print("Media image not detected, using Plex banner")
                                img = get_data("https://michaelyagi.github.io/images/plex_banner.png", debug_output, headerMap, 604800)
                            elif debug_output:
                                print("Using thumbnail type: " + art_type)

                            media_type = "Movie"
                            if is_clip:
                                media_type = "Clip"
                            elif metadata_list[random_index]["type"] == "season":
                                media_type = "TV"
                            elif metadata_list[random_index]["type"] == "album":
                                media_type = "Music"
                            elif metadata_list[random_index]["type"] == "movie":
                                media_type = "Movie"

                            header_text = endpoint_map["title"] + " " + media_type

                            if debug_output:
                                print(header_text)

                            title = ""
                            parent_title = ""
                            grandparent_title = ""
                            for key in metadata_keys:
                                if key == "title":
                                    title = metadata_list[random_index][key]
                                elif key == "parentTitle":
                                    parent_title = metadata_list[random_index][key]
                                elif key == "grandparentTitle":
                                    grandparent_title = metadata_list[random_index][key]

                            if len(grandparent_title) > 0:
                                grandparent_title = grandparent_title + " - "
                            if len(parent_title) > 0:
                                parent_title = parent_title + ": "

                            body_text = grandparent_title + parent_title + title

                            marquee_text = header_text + " - " + body_text
                            max_length = 59
                            if len(marquee_text) > max_length:
                                marquee_text = body_text
                                marquee_text = marquee_text[0:max_length - 3] + "..."

                            if debug_output:
                                print("Marquee text: " + marquee_text)
                                print("Full title: " + header_text + " - " + body_text)
                        else:
                            if debug_output:
                                print("No results for " + endpoint_map["title"])
                            return display_banner(debug_output)

                    if fit_screen == True:
                        rendered_image = render.Image(
                            width = 64,
                            src = img,
                        )
                    else:
                        rendered_image = render.Image(
                            height = (32 - 7),
                            src = img,
                        )

                    return render.Root(
                        child = render.Column(
                            children = [
                                render.Box(
                                    width = 64,
                                    height = 7,
                                    child = render.Row(
                                        expanded = True,
                                        main_align = "space_evenly",
                                        cross_align = "center",
                                        children = [
                                            render.Image(src = icon_img, width = 7, height = 7),
                                            render.Padding(
                                                pad = (0, 1, 0, 0),
                                                child = render.Row(
                                                    expanded = True,
                                                    main_align = "space_evenly",
                                                    cross_align = "center",
                                                    children = [
                                                        render.Marquee(
                                                            scroll_direction = "horizontal",
                                                            width = 64,
                                                            offset_start = 64,
                                                            offset_end = 64,
                                                            child = render.Text(content = marquee_text, font = "tom-thumb", color = font_color),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                                render.Padding(
                                    pad = (0, 0, 0, 0),
                                    child = render.Row(
                                        expanded = True,
                                        main_align = "space_evenly",
                                        cross_align = "center",
                                        children = [rendered_image],
                                    ),
                                ),
                            ],
                        ),
                    )

                else:
                    if debug_output:
                        print("No valid results for " + endpoint_map["title"])
                    return display_banner(debug_output)
            else:
                if debug_output:
                    print("Possible malformed JSON for " + endpoint_map["title"])
                return display_banner(debug_output)
        else:
            if debug_output:
                print("Check API URL & key for " + endpoint_map["title"])
            return display_banner(debug_output)

def display_banner(debug_output):
    img = get_data("https://michaelyagi.github.io/images/plex_banner.png", debug_output, {}, 604800)  # thumb if art not available
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = img, width = 64, height = 32),
            ],
        ),
    )

def get_random_index(item, a_list, debug_output):
    random_index = random.number(0, len(a_list) - 1)
    if debug_output:
        print("Setting cached value for item " + item + ": " + str(random_index))
    return random_index

def get_data(url, debug_output, headerMap = {}, ttl_seconds = 20):
    res = None
    if headerMap != {}:
        res = http.get(url, headers = headerMap, ttl_seconds = ttl_seconds)
    else:
        res = http.get(url, ttl_seconds = ttl_seconds)

    if res == None:
        return None

    if res.status_code != 200:
        if debug_output:
            print("status: " + str(res.status_code))
            print("Requested url: " + str(url))
        return None
    else:
        data = res.body()

        return data

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "plex_server_url",
                name = "Plex Server URL (required)",
                desc = "Your Plex Server URL.",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "plex_api_key",
                name = "Plex API Key (required)",
                desc = "Your Plex API key.",
                icon = "",
                default = "",
            ),
            schema.Text(
                id = "font_color",
                name = "Font color",
                desc = "Font color using Hex color codes. eg, `#FFFFFF`",
                icon = "",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "fit_screen",
                name = "Fit screen",
                desc = "Fit image on screen.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "show_recent",
                name = "Show played",
                desc = "Show 10 last recently played.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "show_added",
                name = "Show added",
                desc = "Show 10 last recently added.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "show_playing",
                name = "Show playing",
                desc = "Show now playing.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "show_library",
                name = "Show library",
                desc = "Show Plex library.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "filter_movie",
                name = "Filter by movies",
                desc = "Show recently played.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "filter_tv",
                name = "Filter by TV shows",
                desc = "Show recently added.",
                icon = "",
                default = True,
            ),
            schema.Toggle(
                id = "filter_music",
                name = "Filter by music",
                desc = "Show now playing.",
                icon = "",
                default = True,
            ),
        ],
    )
