import PlaygroundSupport
import XtreamcodeSwiftAPI
import XtreamServices

let credentials = XtreamCredentials(username: "demo", password: "secret")
var configuration = XtreamcodeSwiftAPI.Configuration(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: credentials
)
configuration.progressStore = UserDefaultsProgressStore(suiteName: "playground.progress")

let api = XtreamcodeSwiftAPI(configuration: configuration)

Task {
    do {
        let vodCategories = try await api.vodCategories()
        print("Catégories VOD:", vodCategories.map(\.name))

        if let firstCategory = vodCategories.first {
            let movies = try await api.vodStreams(in: firstCategory.id)
            if let movie = movies.first {
                let details = try await api.vodDetails(for: movie.streamID)
                print("Synopsis:", details.info?.plot ?? "-")

                let url = try await api.vodStreamURL(for: movie.streamID)
                print("URL de lecture:", url.absoluteString)

                // Sauvegarde de la progression (ex: 2 minutes)
                try await api.saveProgress(contentID: "vod-\(movie.streamID)", position: 120, duration: 360)
            }
        }

        let seriesCategories = try await api.seriesCategories()
        if let seriesCategory = seriesCategories.first {
            let seriesList = try await api.series(in: seriesCategory.id)
            if let show = seriesList.first {
                _ = try await api.seriesDetails(for: show.seriesID)
                let episodeURL = try await api.seriesEpisodeURL(for: show.seriesID, season: 1, episode: 1)
                print("URL épisode:", episodeURL.absoluteString)
            }
        }

        let matches = try await api.search(query: "demo")
        print("Résultats recherche:", matches.map { "\($0.type): \($0.name)" })
    } catch {
        print("Erreur Playground:", error)
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
