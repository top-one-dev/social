# frozen_string_literal: true

module AccountInteractions
  extend ActiveSupport::Concern

  class_methods do
    def following_map(target_account_ids, account_id)
      Follow.where(target_account_id: target_account_ids, account_id: account_id).each_with_object({}) do |follow, mapping|
        mapping[follow.target_account_id] = {
          reblogs: follow.show_reblogs?,
        }
      end
    end

    def followed_by_map(target_account_ids, account_id)
      follow_mapping(Follow.where(account_id: target_account_ids, target_account_id: account_id), :account_id)
    end

    def blocking_map(target_account_ids, account_id)
      follow_mapping(Block.where(target_account_id: target_account_ids, account_id: account_id), :target_account_id)
    end

    def blocked_by_map(target_account_ids, account_id)
      follow_mapping(Block.where(account_id: target_account_ids, target_account_id: account_id), :account_id)
    end

    def muting_map(target_account_ids, account_id)
      Mute.where(target_account_id: target_account_ids, account_id: account_id).each_with_object({}) do |mute, mapping|
        mapping[mute.target_account_id] = {
          notifications: mute.hide_notifications?,
        }
      end
    end

    def requested_map(target_account_ids, account_id)
      FollowRequest.where(target_account_id: target_account_ids, account_id: account_id).each_with_object({}) do |follow_request, mapping|
        mapping[follow_request.target_account_id] = {
          reblogs: follow_request.show_reblogs?,
        }
      end
    end

    def endorsed_map(target_account_ids, account_id)
      follow_mapping(AccountPin.where(account_id: account_id, target_account_id: target_account_ids), :target_account_id)
    end

    def domain_blocking_map(target_account_ids, account_id)
      accounts_map    = Account.where(id: target_account_ids).select('id, domain').each_with_object({}) { |a, h| h[a.id] = a.domain }
      blocked_domains = domain_blocking_map_by_domain(accounts_map.values.compact, account_id)
      accounts_map.reduce({}) { |h, (id, domain)| h.merge(id => blocked_domains[domain]) }
    end

    def domain_blocking_map_by_domain(target_domains, account_id)
      follow_mapping(AccountDomainBlock.where(account_id: account_id, domain: target_domains), :domain)
    end

    private

    def follow_mapping(query, field)
      query.pluck(field).each_with_object({}) { |id, mapping| mapping[id] = true }
    end
  end

  included do
    # Follow relations
    has_many :follow_requests, dependent: :destroy

    has_many :active_relationships,  class_name: 'Follow', foreign_key: 'account_id',        dependent: :destroy
    has_many :passive_relationships, class_name: 'Follow', foreign_key: 'target_account_id', dependent: :destroy

    has_many :following, -> { order('follows.id desc') }, through: :active_relationships,  source: :target_account
    has_many :followers, -> { order('follows.id desc') }, through: :passive_relationships, source: :account

    has_many :group_accounts, inverse_of: :account, dependent: :destroy, source: :account
    has_many :groups, through: :group_accounts

    # Block relationships
    has_many :block_relationships, class_name: 'Block', foreign_key: 'account_id', dependent: :destroy
    has_many :blocking, -> { order('blocks.id desc') }, through: :block_relationships, source: :target_account
    has_many :blocked_by_relationships, class_name: 'Block', foreign_key: :target_account_id, dependent: :destroy
    has_many :blocked_by, -> { order('blocks.id desc') }, through: :blocked_by_relationships, source: :account

    # Mute relationships
    has_many :mute_relationships, class_name: 'Mute', foreign_key: 'account_id', dependent: :destroy
    has_many :muting, -> { order('mutes.id desc') }, through: :mute_relationships, source: :target_account
    has_many :muted_by_relationships, class_name: 'Mute', foreign_key: :target_account_id, dependent: :destroy
    has_many :muted_by, -> { order('mutes.id desc') }, through: :muted_by_relationships, source: :account
    has_many :conversation_mutes, dependent: :destroy
    has_many :domain_blocks, class_name: 'AccountDomainBlock', dependent: :destroy

    # Group Invite relationships
    has_many :group_invite_relationships, class_name: 'GroupInvite', foreign_key: 'account_id', dependent: :destroy
    has_many :group_inviting, -> { order('group_invites.id desc') }, through: :group_invite_relationships, source: :target_account
    has_many :group_invited_by_relationships, class_name: 'GroupInvite', foreign_key: :target_account_id, dependent: :destroy
    has_many :group_invited_by, -> { order('group_invites.id desc') }, through: :group_invited_by_relationships, source: :account

    # Group Invite relationships
    has_many :group_join_private_relationships, class_name: 'GroupJoinPrivate', foreign_key: 'account_id', dependent: :destroy
    has_many :group_join_privating, -> { order('group_join_private.id desc') }, through: :group_join_private_relationships, source: :target_account
    has_many :group_join_privated_by_relationships, class_name: 'GroupJoinPrivate', foreign_key: 'target_account_id', dependent: :destroy
    has_many :group_join_privated_by, -> { order('group_join_private.id desc') }, through: :group_join_privated_by_relationships, source: :account

    has_many :group_approve_join_private_relationships, class_name: 'GroupApproveJoinPrivate', foreign_key: 'account_id', dependent: :destroy
    has_many :group_approve_join_privating, -> { order('group_approve_join_private.id desc') }, through: :group_approve_join_private_relationships, source: :target_account
    has_many :group_approve_join_privated_by_relationships, class_name: 'GroupApproveJoinPrivate', foreign_key: 'target_account_id', dependent: :destroy
    has_many :group_approve_join_privated_by, -> { order('group_approve_join_private.id desc') }, through: :group_approve_join_privated_by_relationships, source: :account

    has_many :health_expert_approve_relationships, class_name: 'HealthExpertApprove', foreign_key: 'account_id', dependent: :destroy
    has_many :health_expert_approving, -> { order('health_expert_approve.id desc') }, through: :health_expert_approve_relationships, source: :target_account
    has_many :health_expert_approved_by_relationships, class_name: 'HealthExpertApprove', foreign_key: 'target_account_id', dependent: :destroy
    has_many :health_expert_approved_by, -> { order('health_expert_approve.id desc') }, through: :health_expert_approved_by_relationships, source: :account
  end

  def follow!(other_account, reblogs: nil, uri: nil)
    reblogs = true if reblogs.nil?

    rel = active_relationships.create_with(show_reblogs: reblogs, uri: uri)
                              .find_or_create_by!(target_account: other_account)

    rel.update!(show_reblogs: reblogs)
    remove_potential_friendship(other_account)

    rel
  end

  def block!(other_account, uri: nil)
    remove_potential_friendship(other_account)
    block_relationships.create_with(uri: uri)
                       .find_or_create_by!(target_account: other_account)
  end

  def mute!(other_account, notifications: nil)
    notifications = true if notifications.nil?
    mute = mute_relationships.create_with(hide_notifications: notifications).find_or_create_by!(target_account: other_account)
    remove_potential_friendship(other_account)

    # When toggling a mute between hiding and allowing notifications, the mute will already exist, so the find_or_create_by! call will return the existing Mute without updating the hide_notifications attribute. Therefore, we check that hide_notifications? is what we want and set it if it isn't.
    if mute.hide_notifications? != notifications
      mute.update!(hide_notifications: notifications)
    end

    mute
  end

  def mute_conversation!(conversation)
    conversation_mutes.find_or_create_by!(conversation: conversation)
  end

  def block_domain!(other_domain)
    domain_blocks.find_or_create_by!(domain: other_domain)
  end

  def unfollow!(other_account)
    follow = active_relationships.find_by(target_account: other_account)
    follow&.destroy
  end

  def unblock!(other_account)
    block = block_relationships.find_by(target_account: other_account)
    block&.destroy
  end

  def unmute!(other_account)
    mute = mute_relationships.find_by(target_account: other_account)
    mute&.destroy
  end

  def unmute_conversation!(conversation)
    mute = conversation_mutes.find_by(conversation: conversation)
    mute&.destroy!
  end

  def unblock_domain!(other_domain)
    block = domain_blocks.find_by(domain: other_domain)
    block&.destroy
  end

  def following?(other_account)
    active_relationships.where(target_account: other_account).exists?
  end

  def blocking?(other_account)
    block_relationships.where(target_account: other_account).exists?
  end

  def domain_blocking?(other_domain)
    domain_blocks.where(domain: other_domain).exists?
  end

  def muting?(other_account)
    mute_relationships.where(target_account: other_account).exists?
  end

  def muting_conversation?(conversation)
    conversation_mutes.where(conversation: conversation).exists?
  end

  def muting_notifications?(other_account)
    mute_relationships.where(target_account: other_account, hide_notifications: true).exists?
  end

  def muting_reblogs?(other_account)
    active_relationships.where(target_account: other_account, show_reblogs: false).exists?
  end

  def requested?(other_account)
    follow_requests.where(target_account: other_account).exists?
  end

  def favourited?(status)
    status.proper.favourites.where(account: self).exists?
  end

  def bookmarked?(status)
    status_bookmarks.where(account: self).exists?
  end

  def reblogged?(status)
    status.proper.reblogs.where(account: self).exists?
  end

  def pinned?(status)
    status_pins.where(status: status).exists?
  end

  def endorsed?(account)
    account_pins.where(target_account: account).exists?
  end

  def group_invite!(other_account, group, reblogs: nil, uri: nil)
    reblogs = true if reblogs.nil?

    rel = group_invite_relationships.create(group: group, target_account: other_account, show_reblogs: reblogs, uri: uri)
    remove_potential_group_invite(other_account, group)

    rel
  end

  def group_join_private!(other_account, group, description, reblogs: nil, uri: nil)
    reblogs = true if reblogs.nil?

    rel = group_join_private_relationships.create(group: group, target_account: other_account, description: description, show_reblogs: reblogs, uri: uri)
    remove_potential_group_join_private(other_account, group)

    rel
  end

  def group_approve_join_private!(other_account, group, reblogs: nil, uri: nil)
    reblogs = true if reblogs.nil?
    
    rel = group_approve_join_private_relationships.create(group: group, target_account: other_account, show_reblogs: reblogs, uri: uri)
    remove_potential_group_approve_join_private(other_account, group)

    rel
  end

  def health_expert_approve!(other_account, reblogs: nil, uri: nil)
    reblogs = true if reblogs.nil?

    rel = health_expert_approve_relationships.create(target_account: other_account, show_reblogs: reblogs, uri: uri)
    remove_potential_health_expert_approve(other_account)

    rel
  end

  def followers_for_local_distribution
    followers.local
             .joins(:user)
             .where('users.current_sign_in_at > ?', User::ACTIVE_DURATION.ago)
  end

  def lists_for_local_distribution
    lists.joins(account: :user)
         .where('users.current_sign_in_at > ?', User::ACTIVE_DURATION.ago)
  end

  private

  def remove_potential_friendship(other_account, mutual = false)
    PotentialFriendshipTracker.remove(id, other_account.id)
    PotentialFriendshipTracker.remove(other_account.id, id) if mutual
  end

  def remove_potential_group_invite(other_account, group)
    PotentialGroupInviteTracker.remove(id, other_account.id, group)
  end

  def remove_potential_group_join_private(other_account, group)
    PotentialGroupJoinPrivateTracker.remove(id, other_account.id, group)
  end

  def remove_potential_group_approve_join_private(other_account, group)
    PotentialGroupApproveJoinPrivateTracker.remove(id, other_account.id, group)
  end

  def remove_potential_health_expert_approve(other_account)
    PotentialHealthExpertApproveTracker.remove(id, other_account.id)
  end
end
