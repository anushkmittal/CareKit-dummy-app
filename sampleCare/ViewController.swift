//
//  ViewController.swift
//  sampleCare
//
//  Created by Anushk Mittal on 5/18/16.
//  Copyright © 2016 Anushk Mittal. All rights reserved.
//

import UIKit
import CareKit
import ResearchKit

class ViewController: UIViewController {
    
    private let sampleData: SampleData
    
    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    
    private var symptomTrackerViewController: OCKSymptomTrackerViewController!
    
    private var taskViewController: ORKTaskViewController!
    
    // private var careCardViewController: OCKCareCardViewController!
    
    required init?(coder aDecoder: NSCoder)
        
    {
        
        sampleData = SampleData(carePlanStore: storeManager.store)
        
        super.init(coder: aDecoder)
        
        // symptomTrackerViewController = createSymptomTrackerViewController()
        // careCardViewController = createCareCardViewController()
        
        // let careCardViewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        // self.navigationController?.pushViewController(careCardViewController, animated: true)
        
        storeManager.delegate = self
        
    }
    
    /*
     private func createCareCardViewController() -> OCKCareCardViewController {
     let viewController = OCKCareCardViewController(carePlanStore: storeManager.store)
     
     // Setup the controller's title and tab bar item
     viewController.title = NSLocalizedString("Care Card", comment: "")
     // viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"carecard"), selectedImage: UIImage(named: "carecard-filled"))
     return viewController
     }
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated...
    }
    
    @IBAction func click(sender: AnyObject) {
        LC_LOAD_DYLIB
        let careCardViewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        // remember to set delegate here when you implement
        self.navigationController?.showViewController(careCardViewController, sender: self)
        print("click")
    }
    
    @IBAction func click1(sender: AnyObject) {
        let symptomTrackerController = OCKSymptomTrackerViewController(carePlanStore: storeManager.store)
        symptomTrackerController.delegate = self
        self.navigationController?.showViewController(symptomTrackerController, sender: self)
        print("click1")
    }
    
}

extension ViewController: OCKSymptomTrackerViewControllerDelegate {
    /// Called when the user taps an assessment on the `OCKSymptomTrackerViewController`.
    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        // Lookup the assessment the row represents.
        guard let activityType = ActivityType(rawValue: assessmentEvent.activity.identifier) else { return }
        guard let sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
        
        /*
         Check if we should show a task for the selected assessment event
         based on its state.
         */
        guard assessmentEvent.state == .Initial ||
            assessmentEvent.state == .NotCompleted ||
            (assessmentEvent.state == .Completed && assessmentEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRunUUID: nil)
        taskViewController.delegate = self
        presentViewController(taskViewController, animated: true, completion: nil)
    }
}

extension ViewController: ORKTaskViewControllerDelegate {
    
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .Completed else { return }
        // Determine the event that was completed and the `SampleAssessment` it represents.
        guard let event = symptomTrackerViewController.lastSelectedAssessmentEvent,
            activityType = ActivityType(rawValue: event.activity.identifier),
            sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
        
        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
        
        // Check assessment can be associated with a HealthKit sample.
        if let healthSampleBuilder = sampleAssessment as? HealthSampleBuilder {
            // Build the sample to save in the HealthKit store.
            let sample = healthSampleBuilder.buildSampleWithTaskResult(taskViewController.result)
            let sampleTypes: Set<HKSampleType> = [sample.sampleType]
            
            // Requst authorization to store the HealthKit sample.
            let healthStore = HKHealthStore()
            healthStore.requestAuthorizationToShareTypes(sampleTypes, readTypes: sampleTypes, completion: { success, _ in
                // Check if authorization was granted.
                if !success {
                    /*
                     Fall back to saving the simple `OCKCarePlanEventResult`
                     in the `OCKCarePlanStore`.
                     */
                    self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                    return
                }
                
                // Save the HealthKit sample in the HealthKit store.
                healthStore.saveObject(sample, withCompletion: { success, _ in
                    if success {
                        /*
                         The sample was saved to the HealthKit store. Use it
                         to create an `OCKCarePlanEventResult` and save that
                         to the `OCKCarePlanStore`.
                         */
                        let healthKitAssociatedResult = OCKCarePlanEventResult(
                            quantitySample: sample,
                            quantityStringFormatter: nil,
                            displayUnit: healthSampleBuilder.unit,
                            displayUnitStringKey: healthSampleBuilder.localizedUnitForSample(sample),
                            userInfo: nil
                        )
                        
                        self.completeEvent(event, inStore: self.storeManager.store, withResult: healthKitAssociatedResult)
                    }
                    else {
                        /*
                         Fall back to saving the simple `OCKCarePlanEventResult`
                         in the `OCKCarePlanStore`.
                         */
                        self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                    }
                    
                })
            })
        }
        else {
            // Update the event with the result.
            completeEvent(event, inStore: storeManager.store, withResult: carePlanResult)
        }
    }
    
    // MARK: Convenience
    
    private func completeEvent(event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.updateEvent(event, withResult: result, state: .Completed) { success, _, error in
            if !success {
                print(error?.localizedDescription)
            }
        }
    }
}

extension ViewController: CarePlanStoreManagerDelegate {
    
    /// Called when the `CarePlanStoreManager`'s insights are updated.
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem]) {
        // Update the insights view controller with the new insights.
        //insightsViewController.items = insights
        
    }
    
}

