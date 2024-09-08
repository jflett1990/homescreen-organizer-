import UIKit
import MobileCoreServices

class AppCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])
    }
    
    func configure(with bundleIdentifier: String) {
        let (appName, appIcon) = getAppInfo(for: bundleIdentifier)
        iconImageView.image = appIcon
        nameLabel.text = appName
    }
    
    private func getAppInfo(for bundleIdentifier: String) -> (String, UIImage?) {
        let workspace = LSApplicationWorkspace.default()
        let apps = workspace.allApplications()
        
        for app in apps {
            if app.bundleIdentifier() == bundleIdentifier {
                let appName = app.localizedName() ?? "Unknown"
                let appIcon = getAppIcon(for: app)
                return (appName, appIcon)
            }
        }
        
        return ("Unknown", nil)
    }
    
    private func getAppIcon(for app: LSApplicationProxy) -> UIImage? {
        guard let iconsDictionary = app.performSelector(NSSelectorFromString("iconsDictionary")).takeUnretainedValue() as? [String: Any],
              let primaryIconDict = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconDict["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last else {
            return nil
        }
        
        let bundlePath = app.performSelector(NSSelectorFromString("bundleURL")).takeUnretainedValue() as! URL
        let iconPath = bundlePath.appendingPathComponent(iconFileName)
        
        if let iconData = try? Data(contentsOf: iconPath) {
            return UIImage(data: iconData)
        }
        
        return nil
    }
}

// MARK: - LSApplicationWorkspace Extension

extension LSApplicationWorkspace {
    @objc static func default() -> LSApplicationWorkspace {
        return LSApplicationWorkspace.performSelector(NSSelectorFromString("defaultWorkspace")).takeUnretainedValue() as! LSApplicationWorkspace
    }
    
    @objc func allApplications() -> [LSApplicationProxy] {
        return self.performSelector(NSSelectorFromString("allApplications")).takeUnretainedValue() as! [LSApplicationProxy]
    }
}

// MARK: - LSApplicationProxy Extension

extension LSApplicationProxy {
    @objc func localizedName() -> String? {
        return self.performSelector(NSSelectorFromString("localizedName")).takeUnretainedValue() as? String
    }
    
    @objc func bundleIdentifier() -> String? {
        return self.performSelector(NSSelectorFromString("bundleIdentifier")).takeUnretainedValue() as? String
    }
}