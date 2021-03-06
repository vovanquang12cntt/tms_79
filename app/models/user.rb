class User < ApplicationRecord
  USER_PARAMS = [:name, :email, :address, :encrypted_password,
    :phone_number].freeze
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable
  before_save :convert_role_to_int

  has_many :user_courses, dependent: :destroy
  has_many :user_tasks, dependent: :destroy
  has_many :courses, through: :user_courses, dependent: :destroy
  has_many :user_subjects, dependent: :destroy
  has_many :subjects, through: :user_subjects, dependent: :destroy

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PHONE_NUMBER_REGEX = /\d[0-9]\)*\z/i

  enum role: {suppervisor: 0, trainee: 1}

  validates :name, presence: true,
    length: {maximum: Settings.user.max_length_name}
  validates :email, presence: true,
    format: {with: VALID_EMAIL_REGEX}, uniqueness: {case_sensitive: false}
  validates :phone_number, presence: true,
    length: {minimum: Settings.user.min_length_phone_number},
    format: {with: VALID_PHONE_NUMBER_REGEX}
  validates :address, presence: true,
    length: {maximum: Settings.user.max_length_address}
  validates :password, :password_confirmation, presence: true,
    length: {minimum: Settings.user.min_length_password}, allow_blank: true

  mount_uploader :avatar, AvatarUploader

  scope :newest, ->{order created_at: :desc}
  scope :with_a_role, ->(role){where(role: role)}
  scope :not_exit_on_course, ->(course_id) do
    where("id not in (?)", UserCourse.user_id_on_course(course_id))
  end
  scope :statistical, ->(task_ids, user_ids) do
    # joins("LEFT JOIN `user_tasks` as ut ON users.id = ut.user_id AND ut.task_id in (?)", task_ids)
    #   .select("`users`.`id`, `users`.`name`, count(ut.id) as count")
    #   .where("`users`.`id` in (?)", user_ids)
    #   .group(:id)
    # query = "SELECT u.id, u.name, count(ut.task_id) as `count`
    #   FROM users as u LEFT JOIN user_tasks as ut
    #   ON u.id = ut.user_id AND ut.task_id in #{task_ids}
    #   WHERE u.id in #{user_ids}
    #   GROUP BY u.id"

    self.find_by_sql("SELECT u.id, u.name, count(ut.task_id) as `count`
      FROM users as u LEFT JOIN user_tasks as ut
      ON u.id = ut.user_id
      GROUP BY u.id")
  end

  def convert_role_to_int
    self.role = User.roles[role]
  end
end
