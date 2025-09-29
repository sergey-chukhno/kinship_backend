# Preview all emails at http://localhost:3000/rails/mailers/test
class TestPreview < ActionMailer::Preview
  def hello
    TestMailer.hello
  end
end
