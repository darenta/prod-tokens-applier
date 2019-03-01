class Order < ActiveRecord::Base

    def apply_discount(price)
      (price / 2).round(2)
    end
end