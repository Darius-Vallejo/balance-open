//
//  ShapeShiftTransferOperator.swift
//  BalanceOpen
//
//  Created by Red Davis on 09/08/2017.
//  Copyright © 2017 Balanced Software, Inc. All rights reserved.
//

import Foundation


internal final class ShapeShiftTransferOperator: TransferOperator
{
    // Private
    private var apiClient: ShapeShiftAPIClient
    private let request: TransferRequest
    private var coinPair: ShapeShiftAPIClient.CoinPair?
    
    // MARK: Initialization
    
    internal init(request: TransferRequest)
    {
        self.request = request
        
        self.apiClient = ShapeShiftAPIClient()
//        self.apiClient.apiKey = "TODO"
    }
    
    internal convenience init(request: TransferRequest, shapeShiftClient: ShapeShiftAPIClient)
    {
        self.init(request: request)
        self.apiClient = shapeShiftClient
    }
    
    // MARK: Quote
    
    func fetchQuote(_ completionHandler: @escaping (_ quote: TransferQuote?, _ error: Error?) -> Void)
    {
        guard let unwrappedCoinPair = self.coinPair else
        {
            self.fetchCoinPair({ [weak self] (success, error) in
                guard let unwrappedSelf = self else { return }
                guard success else
                {
                    completionHandler(nil, error)
                    return
                }
                
                unwrappedSelf.fetchQuote(completionHandler)
            })
            
            return
        }
        
        // Fetch market information
        self.apiClient.fetchMarketInformation(for: unwrappedCoinPair) { [weak self] (marketInformation, error) in
            guard let unwrappedSelf = self else { return }
            guard let unwrappedMarketInformation = marketInformation else
            {
                completionHandler(nil, error)
                return
            }
            
            do
            {
                let transferQuote = try TransferQuote(sourceAmount: unwrappedSelf.request.amount, marketInformation: unwrappedMarketInformation)
                completionHandler(transferQuote, nil)
            }
            catch let error
            {
                completionHandler(nil, error)
            }
        }
    }
    
    // MARK: Transfer
    
    internal func performTransfer(_ completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void)
    {
        guard let unwrappedCoinPair = self.coinPair else
        {
            self.fetchCoinPair({ [weak self] (success, error) in
                guard let unwrappedSelf = self else { return }
                guard success else
                {
                    completionHandler(false, error)
                    return
                }
                
                unwrappedSelf.performTransfer(completionHandler)
            })
            
            return
        }
        
        self.fetchQuote { [weak self] (transferQuote, error) in
            guard let unwrappedSelf = self,
                  let unwrappedQuote = transferQuote else
            {
                completionHandler(false, error)
                return
            }
            
            // Fetch recipient address
            do
            {
                try unwrappedSelf.request.recipient.fetchAddress({ (recipientAddress, error) -> Void in
                    guard let unwrappedRecipientAddress = recipientAddress else
                    {
                        completionHandler(false, error)
                        return
                    }
                    
                    // Create Shape Shift transaction
                    unwrappedSelf.apiClient.createTransaction(amount: unwrappedQuote.recipientAmount, recipientAddress: unwrappedRecipientAddress, pairCode: unwrappedCoinPair.code, returnAddress: nil) { (transactionRequest, error) in
                        guard let unwrappedTransactionRequest = transactionRequest else
                        {
                            completionHandler(false, error)
                            return
                        }
                        
                        // Transaction has been created with Shape Shift.
                        // To complete transaction we need to transfer funds from
                        // the source account to the SS account
                        let withdrawal = Withdrawal(amount: unwrappedTransactionRequest.depositAmount, recipientCryptoAddress: unwrappedTransactionRequest.depositAddress)
                        do
                        {
                            try unwrappedSelf.request.source.make(withdrawal: withdrawal, completionHandler: completionHandler)
                        }
                        catch let error
                        {
                            completionHandler(false, error)
                        }
                    }
                })
            }
            catch
            {
                completionHandler(false, error)
                return
            }
        }
    }
    
    // MARK: Coinpair
    
    private func fetchCoinPair(_ completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void)
    {
        self.apiClient.fetchSupportedCoins { [weak self] (coins, error) in
            guard let unwrappedSelf = self else { return }
            guard let unwrappedCoins = coins else
            {
                completionHandler(false, error)
                return
            }
            
            // Find source coin
            guard let sourceCoin = unwrappedCoins.first(where: { (coin) -> Bool in
                return coin.symbol.lowercased() == unwrappedSelf.request.sourceCurrency.rawValue.lowercased()
            }) else
            {
                completionHandler(false, TransferOperatorError.unsupportedCurrency(currency: unwrappedSelf.request.sourceCurrency))
                return
            }
            
            // Find recipient coin
            guard let recipientCoin = unwrappedCoins.first(where: { (coin) -> Bool in
                return coin.symbol.lowercased() == unwrappedSelf.request.recipientCurrency.rawValue.lowercased()
            }) else
            {
                completionHandler(false, TransferOperatorError.unsupportedCurrency(currency: unwrappedSelf.request.recipientCurrency))
                return
            }
            
            // Complete!
            unwrappedSelf.coinPair = ShapeShiftAPIClient.CoinPair(input: sourceCoin, output: recipientCoin)
            completionHandler(true, nil)
        }
    }
}