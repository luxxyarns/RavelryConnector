# RavelryConnector

This package allows to connect with the Ravelry API.

This is an example SwiftUI code to implement a Ravelry aware app in iOS:


```swift
import SwiftUI
import RavelryConnector

@main
struct TestApp: App {
    @ObservedObject var base = RavelryBase.shared
    @ObservedObject var env = RavelryEnvironment(identifier: "test",
                                                 consumerKey: Constants.getConsumerKey(),
                                                 consumerSecret: Constants.getConsumerSecret(),
                                                 requestTokenUrl: "https://www.ravelry.com/oauth/request_token",
                                                 authorizeUrl: "https://www.ravelry.com/oauth/authorize",
                                                 accessTokenUrl: "https://www.ravelry.com/oauth/access_token",
                                                 scope: "",
                                                 callback: "testapp://callback")
    
    init() {
        base.addRavelryEnvironment(env)
        _ = base.selectEnvironment(env.identifier)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
                .onOpenURL(perform: { url in
                    base.handleURL(url: url)
                    
                })
        }
    }
}

```
Note that consumer key & secret are the details that you get from Ravelry Pro when you create a new app (in this case a oauth 1.0a). 

Regarding "scope" you can add additional items (see the Ravelry API page). 

The above app uses a content view that implements a simple query to get the current user. 

If not yet logged it, it will initiate a login session using Safari and by opening the Ravelry login page. Once logged in, it will return to the app and store the tokens in the keychain. 


```swift

import SwiftUI
import RavelryConnector

struct ContentView: View {
    @EnvironmentObject var env: RavelryEnvironment
    @State var username: String?
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            if let username = username {
                Text("Hello, \(username) !")

            } else {
                Text("Hello, world!")
            }
        }
        .padding()
        .onAppear() {
            env.getCurrentUser { json in
                if let username = env.getUsername(json) {
                    self.username = username
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

```

If you have questions regarding the above code, please let me know via https://www.ravelry.com/people/nordfriese/


