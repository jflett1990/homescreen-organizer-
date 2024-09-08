import UIKit

class FolderViewController: UIViewController {
    private var folder: Folder
    private let folderView: FolderView
    private let folderManager = FolderManager.shared
    
    init(folder: Folder) {
        self.folder = folder
        self.folderView = FolderView(folder: folder)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = folder.name
        view = folderView
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editFolder))
    }
    
    @objc private func editFolder() {
        let alertController = UIAlertController(title: "Edit Folder", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Rename Folder", style: .default) { [weak self] _ in
            self?.renameFolder()
        })
        
        alertController.addAction(UIAlertAction(title: "Add App", style: .default) { [weak self] _ in
            self?.addApp()
        })
        
        alertController.addAction(UIAlertAction(title: "Remove App", style: .default) { [weak self] _ in
            self?.removeApp()
        })
        
        alertController.addAction(UIAlertAction(title: "Change Folder Type", style: .default) { [weak self] _ in
            self?.changeFolderType()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func renameFolder() {
        let alertController = UIAlertController(title: "Rename Folder", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = self.folder.name
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newName = alertController.textFields?.first?.text, !newName.isEmpty else { return }
            self?.updateFolderName(newName)
        }
        
        alertController.addAction(renameAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func addApp() {
        let installedApps = folderManager.getAllInstalledApps()
        let alertController = UIAlertController(title: "Add App", message: "Select an app to add", preferredStyle: .actionSheet)
        
        for app in installedApps {
            if !folder.apps.contains(app.bundleIdentifier) {
                alertController.addAction(UIAlertAction(title: app.name, style: .default) { [weak self] _ in
                    self?.folderManager.addApp(bundleIdentifier: app.bundleIdentifier, to: self?.folder.id ?? UUID())
                    self?.updateFolderView()
                })
            }
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func removeApp() {
        let alertController = UIAlertController(title: "Remove App", message: "Select an app to remove", preferredStyle: .actionSheet)
        
        for app in folder.apps {
            let appName = folderManager.getAppName(for: app) ?? "Unknown"
            alertController.addAction(UIAlertAction(title: appName, style: .default) { [weak self] _ in
                self?.folderManager.removeApp(bundleIdentifier: app, from: self?.folder.id ?? UUID())
                self?.updateFolderView()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func changeFolderType() {
        let alertController = UIAlertController(title: "Change Folder Type", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Regular Folder", style: .default) { [weak self] _ in
            self?.updateFolderType(isSmartFolder: false)
        })
        
        alertController.addAction(UIAlertAction(title: "Smart Folder", style: .default) { [weak self] _ in
            self?.updateFolderType(isSmartFolder: true)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateFolderName(_ newName: String) {
        folder.name = newName
        folderManager.updateFolder(folder)
        updateFolderView()
    }
    
    private func updateFolderType(isSmartFolder: Bool) {
        folder.isSmartFolder = isSmartFolder
        folderManager.updateFolder(folder)
        updateFolderView()
    }
    
    private func updateFolderView() {
        if let updatedFolder = folderManager.getFolder(by: folder.id) {
            folder = updatedFolder
            folderView.updateFolder(updatedFolder)
            title = updatedFolder.name
        }
    }
}