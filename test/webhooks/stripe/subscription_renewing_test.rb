require "test_helper"

class Pay::StripeWebhooksSubscriptionRenewingTest < ActiveSupport::TestCase
  setup do
    @event = OpenStruct.new
    @event.data = JSON.parse(File.read("test/support/fixtures/stripe/subscription_renewing_event.json"), object_class: OpenStruct)
  end

  test "an email is sent to the user when subscription is renewing" do
    @user = User.create!(email: "gob@bluth.com", processor: :stripe, processor_id: @event.data.object.customer)
    subscription = @user.subscriptions.create!(processor: :stripe, processor_id: @event.data.object.subscription, name: "default", processor_plan: "some-plan", status: "active")

    mailer = mock("mailer")
    Pay.stubs(:send_emails).returns(true)
    Pay::UserMailer.expects(:subscription_renewing).with(@user, subscription).returns(mailer)
    mailer.expects(:deliver_later)
    Pay::Webhooks::Stripe::SubscriptionRenewing.new.call(@event)
  end

  test "an email is not sent when subscription can't be found" do
    @user = User.create!(email: "gob@bluth.com", processor: :stripe, processor_id: @event.data.object.customer)
    subscription = @user.subscriptions.create!(processor: :stripe, processor_id: "does-not-exist", name: "default", processor_plan: "some-plan", status: "active")

    mailer = mock("mailer")
    Pay.stubs(:send_emails).returns(true)
    Pay::UserMailer.expects(:subscription_renewing).with(@user, subscription).returns(mailer).never
    mailer.expects(:deliver_later).never
    Pay::Webhooks::Stripe::SubscriptionRenewing.new.call(@event)
  end
end