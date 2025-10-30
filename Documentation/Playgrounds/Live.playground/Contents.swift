import PlaygroundSupport
import XtreamcodeSwiftAPI
import XtreamServices

let credentials = XtreamCredentials(username: "demo", password: "secret")
let configuration = XtreamcodeSwiftAPI.Configuration(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: credentials
)

let api = XtreamcodeSwiftAPI(configuration: configuration)

Task {
    do {
        let categories = try await api.liveCategories()
        print("Catégories live:", categories.map(\.name))

        guard let category = categories.first else { return }
        let streams = try await api.liveStreams(in: category.id)
        print("Flux disponibles:", streams.map(\.name))

        guard let stream = streams.first else { return }
        let epg = try await api.epg(for: stream.id, limit: 5)
        print("EPG rapide:", epg.map(\.decodedTitle ?? stream.title))

        if let url = try await api.liveStreamURL(for: stream.id) {
            print("URL HLS:", url.absoluteString)
        }
    } catch {
        print("Erreur Playground:", error)
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
