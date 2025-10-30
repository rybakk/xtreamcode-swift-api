# ``XtreamcodeSwiftAPI``

Bienvenue dans la documentation officielle du SDK Xtream Codes pour Swift.

## Aperçu

Ce package fournit :

- Une façade `XtreamcodeSwiftAPI` facilitant l’intégration des fonctionnalités Xtream Codes (authentification, catalogue live/VOD, EPG, favoris).
- Une couche réseau basée sur Alamofire, configurable et testable.
- Des modèles `Codable` et des services dédiés (auth, live, VOD, séries, recherche).
- Des adaptateurs futurs pour `async/await`, Combine et callbacks.

## Prochaines étapes

- Consultez la [roadmap](../../docs/roadmap.md) pour la progression.
- Explorez `XtreamcodeSwiftAPI` dans `Sources/XtreamSDKFacade`.
- Contribuez via pull requests et suivez les bonnes pratiques décrites dans `docs/quality.md`.
- Découvrez l’[authentification](Authentication) pour intégrer rapidement le SDK.
- Approfondissez la gestion [Live & EPG](LiveTV) et la stratégie de cache associée.
- Explorez la section [VOD & Films](VOD) pour parcourir les catalogues et générer les URLs de lecture.
- Consultez [Séries TV](Series) pour naviguer dans les saisons/épisodes et utiliser le suivi de progression.
- Centralisez vos recherches avec la page [Recherche transversale](Search).
