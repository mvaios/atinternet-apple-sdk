/*
 This SDK is licensed under the MIT license (MIT)
 Copyright (c) 2015- Applied Technologies Internet SAS (registration number B 403 261 258 - Trade and Companies Register of Bordeaux – France)
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

//
//  CartAwaitingPayment.swift
//  Tracker
//
import Foundation

/// Wrapper class for UpdateCart event tracking (SalesInsight)
public class CartAwaitingPayment: Event {
    
    private var tracker : Tracker
    
    private var screenLabel : String?
    
    /// Cart property
    @objc public lazy var cart : ECommerceCart = ECommerceCart()
    
    /// Products list
    @objc public lazy var products : [ECommerceProduct] = [ECommerceProduct]()
    
    /// Transaction property
    @objc public lazy var transaction : ECommerceTransaction = ECommerceTransaction()
    
    /// Shipping property
    @objc public lazy var shipping : ECommerceShipping = ECommerceShipping()
    
    /// Payment property
    @objc public lazy var payment : ECommercePayment = ECommercePayment()
    
    override var data: [String : Any] {
        get {
            if !cart.properties.isEmpty {
                var cartData = cart.properties
                cartData["s:version"] = cart.version
                _data["cart"] = cartData
            }
            if !payment.properties.isEmpty {
                _data["payment"] = payment.properties
            }
            if !shipping.properties.isEmpty {
                _data["shipping"] = shipping.properties
            }
            if !transaction.properties.isEmpty {
                _data["transaction"] = transaction.properties
            }
            return super.data
        }
    }
    
    init(tracker: Tracker, screenLabel: String?) {
        self.tracker = tracker
        self.screenLabel = screenLabel
        super.init(name: "cart.awaiting_payment")
    }
    
    @objc public func setProducts(products: [ECommerceProduct]) {
        self.products = products
    }
    
    override func getAdditionalEvents() -> [Event] {
        var generatedEvents = super.getAdditionalEvents()
        
        for p in products {
            let pap = ProductAwaitingPayment()
            _ = pap.cart.setAll(obj:
                [
                    "id": String(describing: cart.get(key: "s:id") ?? ""),
                    "version": cart.version
                ])
            if !p.properties.isEmpty {
                _ = pap.product.setAll(obj: p.properties)
            }
            generatedEvents.append(pap)
        }
        
        /// SALES TRACKER
        if let autoSalesTrackerStr = tracker.configuration.parameters[TrackerConfigurationKeys.AutoSalesTracker], autoSalesTrackerStr.toBool() {
            
            let turnoverTaxIncluded = Double(String(describing: cart.get(key: "f:turnovertaxincluded") ?? 0)) ?? 0
            let turnoverTaxFree = Double(String(describing: cart.get(key: "f:turnovertaxfree") ?? 0)) ?? 0
            let cartId = String(describing: cart.get(key: "s:id") ?? "")
            
            let o = tracker.orders.add(cartId, turnover: turnoverTaxIncluded)
            o.status = 3
            o.paymentMethod = 0
            o.isNewCustomer = String(describing: transaction.get(key: "b:firstpurchase") ?? false).toBool()
            _ = o.delivery.set(Double(String(describing: shipping.get(key: "f:costtaxfree") ?? 0)) ?? 0, shippingFeesTaxIncluded: Double(String(describing: shipping.get(key: "f:costtaxincluded") ?? 0)) ?? 0, deliveryMethod: String(describing: shipping.get(key: "s:delivery") ?? ""))
            _ = o.amount.set(turnoverTaxFree, amountTaxIncluded: turnoverTaxIncluded, taxAmount: turnoverTaxIncluded - turnoverTaxFree)
            
            if let promotionalCodes = transaction.get(key: "a:s:promocode") as? [String] {
                _ = o.discount.promotionalCode = promotionalCodes.joined(separator: "|")
            }
            
            let stCart = tracker.cart.set(cartId)
            
            for p in products {
                var stProductId : String
                if let name = (p as RequiredPropertiesDataObject).get(key: "s:$") {
                    stProductId = String(format: "%@[%@]", String(describing: p.get(key: "s:id") ?? ""), String(describing: name))
                } else {
                    stProductId = String(describing: p.get(key: "s:id") ?? "")
                }
                
                let stProduct = stCart.products.add(stProductId)
                stProduct.quantity = Int(String(describing: p.get(key: "n:quantity") ?? 0)) ?? 0
                stProduct.unitPriceTaxIncluded = Double(String(describing: p.get(key: "f:pricetaxincluded") ?? 0)) ?? 0
                stProduct.unitPriceTaxFree = Double(String(describing: p.get(key: "f:pricetaxfree") ?? 0)) ?? 0
                
                if let category1 = p.get(key: "s:category1") {
                    stProduct.category1 = String(format: "[%@]", String(describing: category1))
                }
                
                if let category2 = p.get(key: "s:category2") {
                    stProduct.category2 = String(format: "[%@]", String(describing: category2))
                }
                
                if let category3 = p.get(key: "s:category3") {
                    stProduct.category3 = String(format: "[%@]", String(describing: category3))
                }
                
                if let category4 = p.get(key: "s:category4") {
                    stProduct.category4 = String(format: "[%@]", String(describing: category4))
                }
                
                if let category5 = p.get(key: "s:category5") {
                    stProduct.category5 = String(format: "[%@]", String(describing: category5))
                }
                
                if let category6 = p.get(key: "s:category6") {
                    stProduct.category6 = String(format: "[%@]", String(describing: category6))
                }
            }
            let s = self.tracker.screens.add(self.screenLabel ?? "")
            s.cart = stCart
            s.isBasketScreen = false
            s.sendView()
        }
       
        return generatedEvents
    }
}

/// Wrapper class to manage UpdateCart event instances
public class CartAwaitingPayments : EventsHelper {
    
    private let tracker : Tracker
    
    init(events: Events, tracker: Tracker) {
        self.tracker = tracker
        super.init(events: events)
    }
    
    /// Add cart awaiting payment event tracking
    ///
    /// - Returns: CartAwaitingPayment instance
    @objc public func add(screenLabel: String?) -> CartAwaitingPayment {
        let cap = CartAwaitingPayment(tracker: tracker, screenLabel: screenLabel)
        _ = events.add(event: cap)
        return cap
    }
}
