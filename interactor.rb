require 'dry/transaction'

class Api::V1::Order::CreateCarRequest::Interactor
  include Dry::Transaction

  ISO_8601_REGEX = /^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])$/

  step :apply_discount

  def apply_discount(hash)
    hash = hash.to_h

    account = ::TenantAccount.find_by(email: hash[:tenant_email])
    tenant = ::Tenant.find_by(id: account.tenant_id)
    tenant.locale = hash[:locale]
    tenant.save

    car = ::Car.find_by(id: hash[:car_id])

    date_from = hash[:date_from]
    date_to = hash[:date_to]

    car_price = car.daily_price_by_dates(date_from, date_to, 'rub')

    price = ::Order.new.calculate_comission(car_price, date_from, date_to)

    discount = create_discount(hash)
    if discount.present?
      price = ::Order.new.apply_discount(price)
    end

    if discount.present?
      discount_value = discount.value
      discount_type = ::DiscountType.find_by(id: discount.type_id).title
    end

    Success(hash)
  end

  private

  def create_discount(hash)
    discount = nil
    if hash[:discount].present? && hash[:discount_type].present?
      if ::DiscountType.where(title: hash[:discount_type]).exists?
        discount_type = ::DiscountType.find_by(title: hash[:discount_type])
        discount_params = { :type_id => discount_type.id,
                            :value => hash[:discount]
        }
        discount = ::Discount.create(discount_params)
        discount.save
      end
    end
    discount
  end
end
