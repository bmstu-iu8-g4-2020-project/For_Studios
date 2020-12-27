
import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.windows.first?.rootViewController = self
        setupTabBarItems()
    }
    
    func setupTabBarItems() {
        let trainerItem = UITabBarItem(title: "Студия", image: nil, selectedImage: nil)
        let studiosViewController = UINavigationController(rootViewController: StudiosViewController())
        studiosViewController.navigationBar.topItem?.title = "Студия"
        studiosViewController.tabBarItem = trainerItem
        
        viewControllers = [studiosViewController]
    }
}

