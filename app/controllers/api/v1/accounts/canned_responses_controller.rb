class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy, :show]

  def index
    render json: canned_responses.as_json(methods: :file_path)
  end

  def show
    render json: @canned_response.as_json(methods: :file_path)
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)

    if params.dig(:canned_response, :canned_file).present?
      @canned_response.canned_file.attach(params[:canned_response][:canned_file])
    end

    @canned_response.save!
    render json: @canned_response.as_json(methods: :file_path)
  end

  def update
    @canned_response = CannedResponse.find(params[:id])
  
    # Eliminamos el archivo si se solicita
    if params[:canned_response][:delete_canned_file] == "true" && @canned_response.canned_file.attached?
      @canned_response.canned_file.purge_later
    end
  
    # Adjuntamos un nuevo archivo si es necesario
    if params[:canned_response][:canned_file].present?
      @canned_response.canned_file.purge_later if @canned_response.canned_file.attached?
      @canned_response.canned_file.attach(params[:canned_response][:canned_file])
    end
  
    # Actualizamos los demás atributos
    if @canned_response.update!(canned_response_params)
      render json: @canned_response.as_json(methods: :file_path)
    else
      render json: @canned_response.errors, status: :unprocessable_entity
    end
  end 

  def destroy
    @canned_response = CannedResponse.find(params[:id])
  
    # Eliminamos el archivo adjunto si existe
    @canned_response.canned_file.purge_later if @canned_response.canned_file.attached?
  
    # Eliminamos la respuesta rápida
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content, :canned_file)
  end

  def canned_responses
    scope = Current.account.canned_responses.with_attached_canned_file
    scope = scope.where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%") if params[:search]
    scope
  end
end
