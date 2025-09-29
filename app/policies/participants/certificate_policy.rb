class Participants::CertificatePolicy < Participants::BasePolicy
  def update?
    (record.tutor? || record.voluntary?) && (user.teacher? && user.certify?) || user.admin?
  end
end
