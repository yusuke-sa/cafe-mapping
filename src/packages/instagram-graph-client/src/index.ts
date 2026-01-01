import axios, { AxiosError, AxiosInstance, AxiosRequestConfig } from 'axios';

export type InstagramGraphClientOptions = {
  /**
   * API version. Defaults to v19.0.
   */
  apiVersion?: string;
  /**
   * Instagram User or Page access token.
   */
  accessToken: string;
  /**
   * Optional timeout in milliseconds applied to every request.
   */
  timeoutMs?: number;
};

export type Paging = {
  cursors?: {
    before?: string;
    after?: string;
  };
  next?: string;
  previous?: string;
};

export type PaginatedResponse<T> = {
  data: T[];
  paging?: Paging;
};

export type InstagramUserProfile = {
  id: string;
  username: string;
  account_type?: 'BUSINESS' | 'MEDIA_CREATOR' | 'PERSONAL';
  name?: string;
  followers_count?: number;
  follows_count?: number;
  media_count?: number;
  profile_picture_url?: string;
};

export type InstagramMedia = {
  id: string;
  caption?: string;
  media_type: 'IMAGE' | 'VIDEO' | 'CAROUSEL_ALBUM';
  media_url?: string;
  permalink?: string;
  thumbnail_url?: string;
  timestamp?: string;
  children?: {
    data: Array<{ id: string }>;
  };
};

export type MediaListOptions = {
  fields?: string[];
  limit?: number;
  since?: string;
  until?: string;
};

export type MediaPublishParams = {
  userId: string;
  imageUrl: string;
  caption?: string;
  publish?: boolean;
};

const DEFAULT_PROFILE_FIELDS = [
  'id',
  'username',
  'account_type',
  'name',
  'followers_count',
  'follows_count',
  'media_count',
  'profile_picture_url',
];

const DEFAULT_MEDIA_FIELDS = [
  'id',
  'caption',
  'media_type',
  'media_url',
  'permalink',
  'thumbnail_url',
  'timestamp',
];

export class InstagramGraphError extends Error {
  status?: number;
  code?: string | number;
  type?: string;

  constructor(
    message: string,
    options: { status?: number; code?: string | number; type?: string; cause?: unknown },
  ) {
    super(message, { cause: options.cause });
    this.name = 'InstagramGraphError';
    this.status = options.status;
    this.code = options.code;
    this.type = options.type;
  }
}

export class InstagramGraphClient {
  private readonly http: AxiosInstance;

  constructor(private readonly options: InstagramGraphClientOptions) {
    const apiVersion = options.apiVersion ?? 'v19.0';
    this.http = axios.create({
      baseURL: `https://graph.facebook.com/${apiVersion}`,
      timeout: options.timeoutMs ?? 10_000,
      params: {
        access_token: options.accessToken,
      },
    });
  }

  async getUserProfile(
    userId: string,
    fields: string[] = DEFAULT_PROFILE_FIELDS,
  ): Promise<InstagramUserProfile> {
    return this.request<InstagramUserProfile>({
      url: `/${userId}`,
      method: 'GET',
      params: { fields: fields.join(',') },
    });
  }

  async listRecentMedia(
    userId: string,
    options: MediaListOptions = {},
  ): Promise<PaginatedResponse<InstagramMedia>> {
    const fields = options.fields ?? DEFAULT_MEDIA_FIELDS;
    return this.request<PaginatedResponse<InstagramMedia>>({
      url: `/${userId}/media`,
      method: 'GET',
      params: {
        fields: fields.join(','),
        limit: options.limit,
        since: options.since,
        until: options.until,
      },
    });
  }

  async getMedia(
    mediaId: string,
    fields: string[] = DEFAULT_MEDIA_FIELDS,
  ): Promise<InstagramMedia> {
    return this.request<InstagramMedia>({
      url: `/${mediaId}`,
      method: 'GET',
      params: { fields: fields.join(',') },
    });
  }

  async publishImage(
    params: MediaPublishParams,
  ): Promise<{ id: string; status: 'published' | 'container_created' }> {
    const creationResponse = await this.request<{ id: string }>({
      url: `/${params.userId}/media`,
      method: 'POST',
      params: {
        image_url: params.imageUrl,
        caption: params.caption,
      },
    });

    if (params.publish === false) {
      return { id: creationResponse.id, status: 'container_created' };
    }

    const publishResponse = await this.request<{ id: string }>({
      url: `/${params.userId}/media_publish`,
      method: 'POST',
      params: { creation_id: creationResponse.id },
    });

    return { id: publishResponse.id, status: 'published' };
  }

  static async exchangeLongLivedToken(options: {
    apiVersion?: string;
    appId: string;
    appSecret: string;
    shortLivedToken: string;
    timeoutMs?: number;
  }): Promise<{ access_token: string; token_type: string; expires_in: number }> {
    const apiVersion = options.apiVersion ?? 'v19.0';
    try {
      const response = await axios.get<{
        access_token: string;
        token_type: string;
        expires_in: number;
      }>(`https://graph.facebook.com/${apiVersion}/oauth/access_token`, {
        timeout: options.timeoutMs ?? 10_000,
        params: {
          grant_type: 'fb_exchange_token',
          client_id: options.appId,
          client_secret: options.appSecret,
          fb_exchange_token: options.shortLivedToken,
        },
      });
      return response.data;
    } catch (error) {
      throw toInstagramGraphError(error);
    }
  }

  private async request<T>(config: AxiosRequestConfig): Promise<T> {
    try {
      const response = await this.http.request<T>(config);
      return response.data;
    } catch (error) {
      throw toInstagramGraphError(error);
    }
  }
}

function toInstagramGraphError(error: unknown): InstagramGraphError {
  if (isAxiosError(error)) {
    const errorInfo = error.response?.data as {
      error?: { message?: string; type?: string; code?: string | number };
    } | null;
    const message = errorInfo?.error?.message ?? error.message;
    return new InstagramGraphError(message, {
      status: error.response?.status,
      code: errorInfo?.error?.code,
      type: errorInfo?.error?.type,
      cause: error,
    });
  }

  return new InstagramGraphError('Unknown error while calling Instagram Graph API', {
    cause: error,
  });
}

function isAxiosError(error: unknown): error is AxiosError {
  return axios.isAxiosError(error);
}
