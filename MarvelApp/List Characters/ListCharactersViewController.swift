//
//  ListCharactersViewController.swift
//  MarvelApp
//
//  Created by Homero Oliveira on 04/12/18.
//  Copyright © 2018 Homero Oliveira. All rights reserved.
//

import UIKit

final class ListCharactersViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    let viewModel: ListCharactersViewModel
    
    var state: ChangeState = .notLoaded {
        didSet {
            updateUI(state)
        }
    }
    
    let footerIdentifier = "footer"
    let footerKind = UICollectionView.elementKindSectionFooter
    
    init(viewModel: ListCharactersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "Characters"
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        state = .loading
        viewModel.fetchCharacters { [weak self] (result) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state = result
            }
        }
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(of: CharacterCell.self)
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: footerKind,
                                withReuseIdentifier: footerIdentifier)
    }

    private func updateUI(_ state: ChangeState) {
        switch state {
        case .initial:
            view.unlock()
            collectionView.reloadData()
        case .inserted(let indexPaths):
            collectionView.insertItems(at: indexPaths)
        case .loading:
            view.lock()
        default:
            break
        }
    }
}

extension ListCharactersViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CharacterCell = collectionView.dequeueReusableCell(cellForItemAt: indexPath)
        cell.viewModel = viewModel[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case footerKind:
            let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: footerKind,
                                                            withReuseIdentifier: footerIdentifier,
                                                            for: indexPath)
            return supplementaryView
        default:
            return UICollectionReusableView()
        }
    }
}

extension ListCharactersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectCharacter(at: indexPath)
    }
}

extension ListCharactersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat =  30
        let collectionViewSize = collectionView.frame.size.width - padding
        let percentageOfWidth: CGFloat = 0.50
        let percentageOfHeight: CGFloat = 0.35
        
        return CGSize(width: collectionViewSize * percentageOfWidth,
                      height: collectionView.frame.height * percentageOfHeight)
    }
}

extension ListCharactersViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.hasReachBottom && !viewModel.isLoading && viewModel.hasMore else { return }
        let indexPath = IndexPath(item: 0, section: 0)
        let footer = collectionView.supplementaryView(forElementKind: footerKind, at: indexPath)
        footer?.lock()
        viewModel.fetchCharacters { [weak self, footer] (change) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                footer?.unlock()
                self.state = change
            }
        }
    }
}
