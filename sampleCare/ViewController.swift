//
//  ViewController.swift
//  sampleCare
//
//  Created by Anushk Mittal on 5/18/16.
//  Copyright © 2016 Anushk Mittal. All rights reserved.
//

import UIKit
import CareKit


class ViewController: UIViewController {
    
    private let sampleData: SampleData

    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager

   // private var careCardViewController: OCKCareCardViewController!

    
    
    required init?(coder aDecoder: NSCoder)
    
    {
        
        sampleData = SampleData(carePlanStore: storeManager.store)

        super.init(coder: aDecoder)

     //   careCardViewController = createCareCardViewController()
        
        let careCardViewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        //self.navigationController?.pushViewController(careCardViewController, animated: true)
        
        storeManager.delegate = self

    }
    
    /*
    private func createCareCardViewController() -> OCKCareCardViewController {
        let viewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Care Card", comment: "")
        //viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"carecard"), selectedImage: UIImage(named: "carecard-filled"))
        return viewController
    }
    
    */
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      //  self.navigationController?.pushViewController(careCardViewController, animated: true)

        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated...
    }


    
    @IBAction func click(sender: AnyObject) {
        print("click")
        LC_LOAD_DYLIB
        
        let careCardViewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        print("click")
        self.navigationController?.pushViewController(careCardViewController, animated: true)
        print("click")
        
       // self.navigationController?.pushViewController(careCardViewController, animated: true)
    }

    
}



extension ViewController: CarePlanStoreManagerDelegate {
    
    /// Called when the `CarePlanStoreManager`'s insights are updated.
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem]) {
        // Update the insights view controller with the new insights.
        //insightsViewController.items = insights
        
    }
}
