import UIKit
import RxSwift
import Hyperdrive
import RxHyperdrive
import Gloss
import Representor

class ShowViewController: UIViewController {
    let dispose = DisposeBag()

    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var showPreviewImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let appVC = self.appViewController else {
            print("you need an app VC")
            return
        }

        let network = appVC.context.network
        if let shows = network.root.transitions["show"] {
            let attributes = ["id": "4ea19ee97bab1a0001001908"]
            network.request(shows, parameters: attributes).debug().mapTransitionToObject(Show).subscribeNext { showObject in
                let show = showObject as! Show
                self.showDidLoad(show)
            }
        }

    }

    func showDidLoad(show: Show) {
        showTitleLabel.text = show.name
    }
}

enum ORMError : ErrorType {
    case ORMNoRepresentor
    case ORMNoData
    case ORMCouldNotMakeObjectError
}

extension Observable {
    func mapTransitionToObject(classType: Decodable.Type) -> Observable<Decodable> {

        func resultFromJSON(object:[String: AnyObject], classType: Decodable.Type) -> Decodable? {
            return classType.init(json: object)
        }

        return map { representor in
            guard let rep = representor as? Representor<HTTPTransition> else {
                throw ORMError.ORMNoRepresentor
            }

            if rep.attributes.count == 0 {
                throw ORMError.ORMNoData
            }

            guard let obj = resultFromJSON(rep.attributes, classType: classType)  else {
                throw ORMError.ORMCouldNotMakeObjectError
            }

            if let updated = obj as? Representable {
                updated.updateWithRepresentor(rep)
            }

            return obj
        }
    }
}