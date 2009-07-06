class Payment < ActiveRecord::Base

  NEW = "new"
  CHECKOUT = "checkout"
  DONE = "done"  

  FEE = "fee"
  CHECKOUT_FEE = "checkout_fee"
  DONE_FEE = "done_fee"

end
