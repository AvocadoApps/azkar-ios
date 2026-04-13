import AudioPlayer
import FactoryKit
import Library

extension Container {

    var preferences: Factory<Preferences> {
        self { Preferences.shared }
            .singleton
    }

    var deeplinker: Factory<Deeplinker> {
        self { MainActor.assumeIsolated { Deeplinker.shared } }
            .singleton
    }

    var quickActionDispatcher: Factory<QuickActionDispatcher> {
        self { MainActor.assumeIsolated { QuickActionDispatcher.shared } }
            .singleton
    }

    var subscriptionManager: Factory<SubscriptionManagerType> {
        self {
            if CommandLine.arguments.contains("DEMO_SUBSCRIPTION") {
                DemoSubscriptionManager()
            } else {
                SubscriptionManager.shared
            }
        }
        .singleton
    }

    var notificationsHandler: Factory<NotificationsHandler> {
        self { NotificationsHandler.shared }
            .singleton
    }

    var player: Factory<Player> {
        self { Player(player: AudioPlayer()) }
            .singleton
    }

    var fontsService: Factory<FontsServiceType> {
        self { FontsService() }
            .singleton
    }

    var appAnalyticsStack: Factory<AppAnalyticsStack> {
        self {
            AppAnalyticsStack(
                preferences: self.preferences(),
                notificationsHandler: self.notificationsHandler()
            )
        }
        .singleton
    }

    var localAnalytics: Factory<AppAnalyticsTracking> {
        self { self.appAnalyticsStack().localAnalytics }
            .singleton
    }

    var appDependencies: Factory<AppDependencies> {
        self {
            let analyticsStack = self.appAnalyticsStack()
            return AppDependencies(
                preferences: self.preferences(),
                player: self.player(),
                analytics: analyticsStack.localAnalytics,
                analyticsDatabase: analyticsStack.processedEventsStore
            )
        }
        .singleton
    }

    var appNavigator: Factory<AppNavigator> {
        self { MainActor.assumeIsolated {
            AppNavigator(
                dependencies: self.appDependencies(),
                deeplinker: self.deeplinker(),
                analytics: self.localAnalytics()
            )
        } }
        .singleton
    }

    var mainMenuViewModel: Factory<MainMenuViewModel> {
        self { MainActor.assumeIsolated {
            let dependencies = self.appDependencies()
            return MainMenuViewModel(
                databaseService: dependencies.databaseService,
                preferencesDatabase: dependencies.preferencesDatabase,
                navigator: self.appNavigator(),
                preferences: dependencies.preferences,
                player: dependencies.player,
                articlesService: dependencies.articlesService,
                adsService: dependencies.adsService,
                analytics: dependencies.analytics
            )
        } }
        .singleton
    }

    var rootViewModel: Factory<RootViewModel> {
        self { MainActor.assumeIsolated {
            RootViewModel(mainMenuViewModel: self.mainMenuViewModel())
        } }
        .singleton
    }

    var articleShareActionHandler: Factory<ArticleShareActionHandler> {
        self { ArticleShareActionHandler() }
            .singleton
    }

    var zikrShareActionHandler: Factory<ZikrShareActionHandler> {
        self { ZikrShareActionHandler() }
            .singleton
    }
}
