//
//  TableRowData.swift
//  Red Davis
//
//  Created by Red Davis on 10/11/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import UIKit


// MARK: TableSection
typealias TableIndexPath = (section: TableSection, row: TableRow)

internal struct TableSection
{
    let title: String?
    let rows: [TableRow]
}

extension Array where Element == TableSection {
    subscript (indexPath: IndexPath) -> TableIndexPath {
            let section = self[indexPath.section]
            let row = section.rows[indexPath.row]
            return (section, row)
    }
}

// MARK: TableRow

internal struct TableRow
{
    // Internal
    typealias CellPreparationHandler = (_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell
    typealias ActionHandler = (_ indexPath: IndexPath) -> Void
    typealias DeletionHandler = (_ indexPath: IndexPath) -> Void
    
    internal let cellPreparationHandler: CellPreparationHandler
    internal var actionHandler: ActionHandler?
    internal var deletionHandler: DeletionHandler?
    
    internal var isDeletable: Bool {
        return self.deletionHandler != nil
    }
    
    // MARK: Initialization
    
    internal init(cellPreparationHandler: @escaping CellPreparationHandler)
    {
        self.cellPreparationHandler = cellPreparationHandler
    }
}
