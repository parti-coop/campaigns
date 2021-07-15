class Api::V1::CampaignsController < ApplicationController

  def signs_recent
    campaign = Campaign.find(params[:id])
    max_count = [params[:max_count]&.to_i, 32].min
    signs = campaign.signs.present.recent.take(max_count).map{ |x| { signer_name: x.user_name, body: x.body, signed_at: x.created_at, sequence_no: campaign.signs.where('id <= ?', x).count } }
    render json: signs
  end

end
